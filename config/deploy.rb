require "bundler/capistrano"

server "50.116.45.116", :web, :app, :db, primary: true
set :user, "deployer"
set :application, "cap_app"

set :is_default, false
set :setup_ssl, true
set :ssl_cert, "final.crt"
set :ssl_cert_key, "site.key"

set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:ravindrakumawat/cap_app.git"
set :branch, "master"

ssh_options[:forward_agent] = true

load "config/recipes/base"
load "config/recipes/security"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/mysql"
load "config/recipes/nodejs"
load 'config/recipes/postfix'
load 'config/recipes/ruby_installer'
load "config/recipes/check"

default_run_options[:pty] = true

after "deploy", "deploy:cleanup"

require 'foreman/capistrano'
namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :setup, :roles => :app do
    set :worker_concurrency, 5
    template("foreman_procfile.erb","#{release_path}/Procfile")
  end
end
before "foreman:export", "foreman:setup"

after "deploy:restart", "foreman:export", "foreman:restart"