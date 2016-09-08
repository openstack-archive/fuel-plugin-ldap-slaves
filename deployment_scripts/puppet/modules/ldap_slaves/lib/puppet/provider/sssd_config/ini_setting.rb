Puppet::Type.type(:sssd_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do
  def section
    if resource[:name].start_with?("domain/")
      resource[:name].split('/', 3)[0] + '/' + resource[:name].split('/', 3)[1]
    else    
      resource[:name].split('/', 2).first
    end
  end    
  def setting
    if resource[:name].start_with?("domain/")
      resource[:name].split('/', 3)[2]
    else
      resource[:name].split('/', 2).last
    end
  end
  def self.file_path
    '/etc/sssd/sssd.conf'
  end
end