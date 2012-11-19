namespace :ruby_installer do
  desc "Install latest stable release of nginx"
  task :install, :roles => [:web, :app] do
    run "#{sudo} apt-get -y -qq install ruby1.8 ruby1.9.3 rubygems ruby-switch"
    run "#{sudo} ruby-switch --set ruby1.9.1"
  end
  after "deploy:install", "ruby_installer:install"
  after "ruby_installer:install", "ruby_installer:essential_gems"

  desc "Essential Gems"
  task :essential_gems, :roles => [:web, :app] do
    run "#{sudo} REALLY_GEM_UPDATE_SYSTEM=true gem update --system"
    run "#{sudo} gem install request-log-analyzer rake"
    run "#{sudo} gem install bundler"
  end
end