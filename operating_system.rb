require 'json'
require 'open-uri'
require 'fileutils'
require './console_logger'
require 'docker'

class OperatingSystem
  BASIC_AUTH = {http_basic_authentication: ["view", "password"]}

  def initialize(os_prefix, dist_json_url)
    @os_prefix = os_prefix

    @unsigned_bins_dir = "#{Dir.pwd}/#{os_prefix}/unsigned"
    @signed_bins_dir = "#{Dir.pwd}/#{os_prefix}/signed"

    @dist_data = JSON.parse(open(dist_json_url, 'r', BASIC_AUTH).read)
    @os_data = @dist_data.find {|data| data['name'] == os_prefix}

    Dir.mkdir @signed_bins_dir unless File.exist?(@signed_bins_dir)
    Dir.mkdir @unsigned_bins_dir unless File.exist?(@unsigned_bins_dir)
  end

  def download_binaries
    FileUtils.mkdir_p @unsigned_bins_dir unless File.exist?(@unsigned_bins_dir)
    list_of_bins.each do |bin|
      ConsoleLogger.info "Downloading #{bin['name']}."
      download bin['url'], "#{@unsigned_bins_dir}/#{bin['name']}"
      ConsoleLogger.info "Downloaded #{bin['name']}."
    end
  end

  def validate_bins
    bin_count = list_of_bins.length
    raise "Was expecting there to be at-least 2 files for #{@os_prefix}, got #{bin_count}" unless bin_count == expected_bins
  end

  def create_signer_container

    container = Docker::Container.all(:all => true).find {|c| c.info["Names"].include?("/#{@os_prefix}-signer")}
    container.delete(:force => true) if container

    container = Docker::Container.create(:name => "#{@os_prefix}-signer",
                                         :Image => 'bdpiprava/gocd-agent-dind:0.0.2',
                                         :Privileged => true,
                                         :Interactive => false,
                                         :AttachStdout => true,
                                         :AttachStderr => true,
                                         :detach => true,
                                         :RM => true,
                                         :Env => ['GPG_SIGNING_KEY_ID=8816C449',
                                                  "SIGNING_USER=#{Process.uid}",
                                                  "SIGNING_GROUP=#{Process.gid}"
                                         ],
                                         :Mounts => [
                                             {:Type => 'bind', :Source => @signed_bins_dir, :Target => '/signed', :RW => true},
                                             {:Type => 'bind', :Source => @unsigned_bins_dir, :Target => '/unsigned', :RW => true},
                                             {:Type => 'bind', :Source => "#{tmp_dir}/.gnupg", :Target => '/root/.gnupg', :RW => true},
                                         ]
    )

    container.start

    puts container.json.to_json
  end

  private

  def expected_bins
    2
  end

  def download url, location
    IO.copy_stream(open(url, 'r', BASIC_AUTH), location)
  end
end

class Mac < OperatingSystem
  def initialize(binaries_url)
    super('osx', binaries_url)
  end

  def list_of_bins
    @os_data['files']
  end

  def sign
    validate_bins
    # download_binaries
    create_signer_container
  end
end