set_default(:postfix_domain) { "localhost" }

namespace :postfix do
  desc "Install postfix"
  task :install, :roles => :app do
    run "echo 'postfix postfix/mailname string #{postfix_domain}' | #{sudo} debconf-set-selections"
    run "echo 'postfix postfix/main_mailer_type select Internet Site' | #{sudo} debconf-set-selections"
    run "#{sudo} apt-get -y -qq install postfix bsd-mailx"
  end
  after "deploy:install", "postfix:install"
end