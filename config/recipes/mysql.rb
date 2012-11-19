# TASKS:
# mysql:install - downloads mysql packages
# mysql:setup - creates and copies database.yml file
# mysql:create_database - creates DB in mysql console
# mysql:symlink - on deploy creates symlink from #{current_path} to #{shared_path}

set_default(:mysql_host, "127.0.0.1")
set_default(:mysql_user) { "root" }
set_default(:mysql_password) { Capistrano::CLI.password_prompt "! MySQL root password: " }
set_default(:mysql_database) { "#{application}_#{rails_env}" }

namespace :mysql do

  desc "Install the latest stable release of MySql."
  task :install, :roles => :db, :only => {:primary => true} do
    run "echo 'mysql-server-5.1 mysql-server/root_password password #{mysql_password}' | #{sudo} debconf-set-selections"
    run "echo 'mysql-server-5.1 mysql-server/root_password_again password #{mysql_password}' | #{sudo} debconf-set-selections"
    run "echo 'mysql-server-5.1 mysql-server/start_on_boot boolean true' | #{sudo} debconf-set-selections"
    run "#{sudo} apt-get -y -qq install mysql-server mysql-client libmysqlclient-dev mytop"
  end
  after "deploy:install", "mysql:install"


  desc "Create a database and user for this application."
  task :create_database, :roles => :db, :only => {:primary => true} do
    put "create database if not exists #{mysql_database};
grant all on #{mysql_database}.* to '#{mysql_user}'@'#{mysql_host}' identified by '#{mysql_password}';", "/tmp/mysql_create"
    run "mysql -u #{mysql_user} -p'#{mysql_password}' < /tmp/mysql_create"
    run "rm /tmp/mysql_create"
  end
  after "deploy:setup", "mysql:create_database"


  desc "Generate the database.yml configuration file."
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "mysql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "mysql:setup"


  desc "Symlink the database.yml file into latest release"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "mysql:symlink"
end