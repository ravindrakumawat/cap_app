set_default(:deployer_password) { Capistrano::CLI.password_prompt "UNIX password for user #{deploy_user}: " }
set_default(:ssh_public_key) { "#{ENV['HOME']}/.ssh/cap_app.pub" }
set_default(:deploy_group) { "sudo" }
set_default(:pubkey_authentication) { "yes" }
set_default(:permit_root_login) { "no" }
set_default(:password_authentication) { "no" }
set_default(:ssh_port) { 22 }

namespace :security do

  desc "Creates user for deployment #{user}"
  task :create_user do
    close_sessions
    set :deploy_user, user # saves the content of user variable, so it can be restored later
    set :user, "root" # sets user to root for first login

    template("app_sudoers.erb","/etc/sudoers.d/#{application}_sudoers",{:mode => "0440"})
    template("environment.erb","/tmp/environment")
    run "#{sudo} mv /tmp/environment /etc/environment"
    template("gemrc","/etc/skel/.gemrc")
    run "#{sudo} mkdir -p /etc/skel/bin /etc/skel/backup /etc/skel/.ssh"
    run "#{sudo} useradd --create-home --shell '/bin/bash' --user-group --groups #{deploy_group} #{deploy_user}"
    server = sessions.keys.first
    put File.read(ssh_public_key), "/tmp/authorized_keys"
    run "#{sudo} mv /tmp/authorized_keys `grep #{deploy_user} /etc/passwd | cut -d: -f6`/.ssh/authorized_keys"
    run "#{sudo} chown #{deploy_user} `grep #{deploy_user} /etc/passwd | cut -d: -f6`/.ssh/authorized_keys"
    run "#{sudo} chmod 600 `grep #{deploy_user} /etc/passwd | cut -d: -f6`/.ssh/authorized_keys"
    run "#{sudo} chmod 700 `grep #{deploy_user} /etc/passwd | cut -d: -f6`/.ssh"
    run "#{sudo} passwd -l #{deploy_user}"
    puts "User #{deploy_user} created!"
  end
  after "security:create_user", "security:setup_firewall", "security:configure_sshd"

  desc "Setup a firewall with UFW"
  task :setup_firewall, :roles => :web do
    run "#{sudo} apt-get -y -qq install ufw"
    run "#{sudo} ufw default deny"
    run "#{sudo} ufw allow #{ssh_port}/tcp"
    run "#{sudo} ufw allow http"
    run "#{sudo} ufw allow https"
    run "#{sudo} ufw --force enable"
  end

  desc "Configure SSH for hard ssh access requirements"
  task :configure_sshd do
    run "#{sudo} cp /etc/ssh/sshd_config /etc/sshd_config.backedup"
    template "sshd_config.erb", "/etc/ssh/sshd_config"
    run "#{sudo} service ssh restart"
  end

end