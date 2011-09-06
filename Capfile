set :gateway, "www.capify.org"
role :libs, "private.capify.org", "mail.capify.org"
role :files, "fuchsia.capify.org"

task :search_libs do
  run "ls -x1 /usr/lib | grep -i xml"
end

task :count_libs do
  run "ls -x1 /usr/lib | wc -l"
end

task :show_free_space, :rolse => :files do
  run "df -f /"
end

