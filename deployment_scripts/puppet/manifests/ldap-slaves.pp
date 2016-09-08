$plugin_settings = parseyaml($astute_settings_yaml)
notice('MODULAR: ldap-slaves')
class {'ldap_slaves': }