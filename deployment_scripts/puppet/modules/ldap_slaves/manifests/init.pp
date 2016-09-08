class ldap_slaves {
  $domain_name         = $::plugin_settings['ldap-slaves']['domain_name']
  $uri                 = $::plugin_settings['ldap-slaves']['uri']
  $binduser            = $::plugin_settings['ldap-slaves']['binduser']
  $bindpass            = $::plugin_settings['ldap-slaves']['bindpass']
  $use_tls             = $::plugin_settings['ldap-slaves']['use_tls']
  $search_base         = $::plugin_settings['ldap-slaves']['search_base']
  $access_filter       = $::plugin_settings['ldap-slaves']['access_filter']
  $home_directory_attr = $::plugin_settings['ldap-slaves']['home_directory_attr']
  $ssh_key_attr        = $::plugin_settings['ldap-slaves']['ssh_key_attr']

  package { 'libpam-sss':
    ensure => 'installed',
  } ->

  package { 'libnss-sss':
    ensure => 'installed',
  } ->

  package { 'libnss-ldap':
    ensure => 'installed',
  } ->

  package { 'sssd':
    ensure => 'installed',
  }

  file { '/etc/sssd/sssd.conf':
    ensure  => present,
    content => template('ldap_slaves/sssd_conf.erb'),
    mode    => 0600,
    require => Package['sssd'],
  }

  service { 'sssd':
    enable  => true,
    ensure  => running,
    require => File['/etc/sssd/sssd.conf'],
  }

  service { 'ssh':
    ensure      => running,
  }

  $ldap_uri = join(any2array($uri), ',')

  sssd_config {
    "domain/${domain_name}/ldap_uri":                 value => $ldap_uri;
    "domain/${domain_name}/ldap_default_bind_dn":     value => $binduser;
    "domain/${domain_name}/ldap_default_authtok":     value => $bindpass;
    "domain/${domain_name}/ldap_search_base":         value => $search_base;
    "domain/${domain_name}/ldap_user_home_directory": value => $home_directory_attr;
    "domain/${domain_name}/ldap_user_ssh_public_key": value => $ssh_key_attr;
  }

  if $use_tls {
    $tls_cacert = $::plugin_settings['ldap-slaves']['tls_cacert']
    $tls_capath = "/etc/ssl/certs/sssd-ldap-ca.crt"

    file { $tls_capath:
      ensure  => file,
      mode    => 0644,
      content => $tls_cacert,
    }

    sssd_config {
      "domain/${domain_name}/ldap_tls_cacert":    value => $tls_capath;
    }
  }

  unless empty($ldap_access_filter) {
    sssd_config {
      "domain/${domain_name}/ldap_access_filter": value => $access_filter;
    }
  }

  file_line {'sshd_keyscommand':
    line => "AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys",
    path => '/etc/ssh/sshd_config',
  } ->

  file_line {'sshd_keyscommanduser':
    line => "AuthorizedKeysCommandUser nobody",
    path => '/etc/ssh/sshd_config',
  }

  file_line {'sssd_pam':
    line  => "session\trequired\tpam_mkhomedir.so\tskel=/etc/skel/\tumask=0022",
    path  => '/etc/pam.d/common-session',
    after => "session\trequired\tpam_unix.so ",
  }

  File_line['sshd_keyscommanduser'] ~> Service['ssh']
  File['/etc/sssd/sssd.conf'] -> Sssd_config <||>
  Sssd_config <||> ~> Service['sssd']
}