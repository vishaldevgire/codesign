require 'open-uri'
require 'json'
require 'base64'
require './operating_system'
require 'pathname'

# go_base_url = "https://build.gocd.org/go"
# job_identifier = ENV['GO_INSTALLER_JOB_IDENTIFIER'] || (raise "GO_INSTALLER_JOB_IDENTIFIER is not set. e.g. distributions-all/331/dist-all/1/all")
#
# username = 'view'
# password = 'password'
# unsigned_bin_location = "./unsigned"

ENV['UNSIGNED_BIN_DIRECTORY'] || (raise "UNSIGNED_BIN_DIRECTORY is not set. e.g. /mydir/unsigned")
ENV['SIGNED_BIN_DIRECTORY'] || (raise "SIGNED_BIN_DIRECTORY is not set. e.g. /mydir/signed")
ENV['GPG_SIGNING_KEY_ID'] || (raise "GPG_SIGNING_KEY_ID is not set. e.g. 7722C545")

unsigned_bin_dir   = Pathname.new(ENV['UNSIGNED_BIN_DIRECTORY']).expand_path
signed_bin_dir     = Pathname.new(ENV['SIGNED_BIN_DIRECTORY']).expand_path
gpg_signing_key_id = ENV['GPG_SIGNING_KEY_ID']


task :clean do
  rm_rf "#{signed_bin_dir}"
  mkdir_p "#{signed_bin_dir}"
end

task :centos => [:clean] do
  cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

  sh("rpm --addsign --define \"_gpg_name #{gpg_signing_key_id}\" #{signed_bin_dir.join('*.rpm')}")
  sh("gpg --armor --output /tmp/GPG-KEY-GOCD --export #{gpg_signing_key_id}")
  sh("rpm --import /tmp/GPG-KEY-GOCD")
  sh("rpm --checksig #{signed_bin_dir.join('*.rpm')}")
end

task :ubuntu => [:clean] do
  cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

  sh("dpkg-sig --verbose --sign builder -k #{gpg_signing_key_id} #{signed_bin_dir}/*.deb")
  sh("gpg --armor --output /tmp/GPG-KEY-GOCD --export #{gpg_signing_key_id}")
  sh("apt-key add /tmp/GPG-KEY-GOCD")
  sh("dpkg-sig --verbose --verify #{signed_bin_dir}/*.deb")
end

# task :zip => [:clean] do
#   unsigned_bin_dir
#       .children.select {|path| path.basename.extname == '.zip'}
#       .each do |file|
#     _asc = "#{signed_bin_dir.join(file.basename)}.asc"
#     sh("gpg --default-key #{gpg_signing_key_id} --armor --detach-sign --sign --output #{_asc} #{file}")
#     cp "#{file}", "#{signed_bin_dir.join(file.basename)}"
#     sh("gpg --default-key #{gpg_signing_key_id} --verify #{_asc}")
#   end
# end

task :zip => [:clean] do
  cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"
  signed_bin_dir
      .children.select {|path| path.basename.extname == '.zip'}
      .each do |file|
        sig = "#{file}.asc"
        sh("gpg --default-key #{gpg_signing_key_id} --armor --detach-sign --sign --output #{sig} #{file}")
        sh("gpg --default-key #{gpg_signing_key_id} --verify #{sig}")
      end
end


task :test => [:clean] do
  puts "#{gpg_signing_key_id}"
  puts "#{unsigned_bin_dir}"
  puts "#{signed_bin_dir}"
  cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"
end

task :default => [:test]