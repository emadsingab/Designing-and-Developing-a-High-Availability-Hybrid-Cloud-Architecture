Vagrant.configure("2") do |config|

  # --- Database Server (db01) ---
  config.vm.define "db01" do |db|
    db.vm.box = "bento/ubuntu-22.04"
    db.vm.hostname = "Cairo.db01.domain.com"
    db.vm.network "private_network", ip: "192.168.100.10"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
    db.vm.provision "shell", path: "db-setup.sh"
  end

  # --- Web Servers (web01, web02, web03) ---
  (1..3).each do |i|
    config.vm.define "web0#{i}" do |web|
      web.vm.box = "eurolinux-vagrant/centos-stream-9"
      web.vm.hostname = "Cairo.web0#{i}.domain.com"
      web.vm.network "private_network", ip: "192.168.100.1#{i}"
      web.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = "2"
      end
      web.vm.provision "shell", path: "web-setup.sh"
    end
  end

  # --- Load Balancer (lb01) ---
  config.vm.define "lb01" do |lb|
    lb.vm.box = "eurolinux-vagrant/centos-stream-9"
    lb.vm.hostname = "Cairo.lb01.domain.com"
    lb.vm.network "private_network", ip: "192.168.100.20"
    lb.vm.network "public_network", ip: "192.168.1.150"
    lb.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
    lb.vm.provision "shell", path: "lb-setup.sh"
  end
#  # --- Load Balancer (lb02) ---
#   config.vm.define "lb02" do |lb|
#     lb.vm.box = "eurolinux-vagrant/centos-stream-9"
#     lb.vm.hostname = "Cairo.lb02.domain.com"
#     lb.vm.network "private_network", ip: "192.168.100.22"
#     # lb.vm.network "public_network", ip: "192.168.1.150"
#     lb.vm.provider "virtualbox" do |vb|
#       vb.memory = "1024"
#       vb.cpus = "1"
#     end
#     # lb.vm.provision "shell", path: "lb-setup-new.sh"
#   end
  
  # --- DNS Server (dns01) ---
  config.vm.define "dns01" do |dns|
    dns.vm.box = "eurolinux-vagrant/centos-stream-9"
    dns.vm.hostname = "Cairo.dns01.domain.com"
    dns.vm.network "private_network", ip: "192.168.100.30"
    dns.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = "1"
    end
    dns.vm.provision "shell", path: "dns-setup.sh"
  end

end
