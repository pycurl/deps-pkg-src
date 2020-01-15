Vagrant.configure(2) do |config|
  config.vm.box = "generic/ubuntu1804"
  config.vm.synced_folder File.dirname(__FILE__), "/share"
  config.vm.define 'bionic'
  #config.vm.provider 'libvirt'
end
