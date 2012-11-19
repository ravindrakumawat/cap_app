def template(from, to, options = {})
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to, options
end

def close_sessions # method is needed when changing user from root to deployer. Sessions need to close
  sessions.values.each { |session| session.close }
  sessions.clear
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end


namespace :deploy do

  desc "Install everything onto the server"
  task :install do
    run "#{sudo} apt-get -y -qq install python-software-properties wget vim less curl git-core"
    run "#{sudo} add-apt-repository ppa:brightbox/ruby-ng-experimental -y"
    run "#{sudo} add-apt-repository ppa:chris-lea/node.js -y"
    run "#{sudo} apt-get -y -qq update"
     run "#{sudo} dpkg-reconfigure --frontend noninteractive tzdata"
  end
end