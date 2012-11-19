set_default(:setup_ssl) { false }

namespace :nginx do
  desc "Install latest stable release of nginx"
  task :install, :roles => :web do
    run "#{sudo} apt-get -y -qq install nginx"
  end
  after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup, :roles => :web do
    if setup_ssl
      put File.read("config/#{ssl_cert}"), "#{shared_path}/#{ssl_cert}"
      put File.read("config/#{ssl_cert_key}"), "#{shared_path}/#{ssl_cert_key}"
    end
    template "nginx_unicorn.erb", "/tmp/nginx_conf-#{application}"
    #template "nginx.mime.types.erb", "/tmp/nginx.mime.types"
    run "#{sudo} mv /tmp/nginx_conf-#{application} /etc/nginx/sites-enabled/#{application}"
    #run "#{sudo} mv /tmp/nginx.mime.types /etc/nginx/mime.types"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    restart
  end
  after "deploy:setup", "nginx:setup"

  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command, :roles => :web do
      run "#{sudo} service nginx #{command}"
    end
  end
end