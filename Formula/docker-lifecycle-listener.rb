class DockerRequirement < Requirement
  fatal true

  satisfy(build_env: false) { which("docker") }

  def message
    <<~EOS
      docker is required; install it via one of:
        brew install docker
        brew install --cask docker
    EOS
  end
end

class DockerLifecycleListener < Formula
  desc "Allows running arbitrary commands on start and stop of the docker daemon"
  homepage "https://github.com/Mahoney/docker-lifecycle-listener"
  url "https://github.com/Mahoney/docker-lifecycle-listener/archive/1.0.3.tar.gz"
  sha256 "51a5e5d20389065e19be4011072d5032507f2a5db68d6e5a9c8c067e0093511b"
  license "AGPL-3.0-or-later"

  bottle :unneeded

  depends_on DockerRequirement

  NOTIFIER_NAME = "docker-lifecycle-notifier".freeze

  def install
    sbin.install "docker-lifecycle-listener.sh"

    system "docker", "build", ".", "-t", NOTIFIER_NAME
    begin
      system "docker", "rm", "-f", NOTIFIER_NAME
    rescue BuildError
      # deliberately swallowing - don't care if the container doesn't exist
    end
    system "docker", "run",
           "--detach",
           "--restart", "always",
           "--name", NOTIFIER_NAME,
           NOTIFIER_NAME

    (etc/"docker-lifecycle-listener.d/on_start").mkpath
    (etc/"docker-lifecycle-listener.d/on_stop").mkpath
  end

  def caveats
    <<~EOS
      A full uninstall requires removing the docker container and image:
        docker rm -f #{NOTIFIER_NAME}
        docker image rm #{NOTIFIER_NAME}

      To prevent docker-lifecycle-listener being a backdoor for untrusted code
      it requires #{etc}/docker-lifecycle-listener.d and everything
      within it to be owned by root and only writable by root.

      You must change the ownership manually:
        sudo chown -R root:admin #{etc}/docker-lifecycle-listener.d
    EOS
  end

  plist_options startup: true

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>EnvironmentVariables</key>
          <dict>
            <key>PATH</key>
            <string>/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
          </dict>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_sbin}/docker-lifecycle-listener.sh</string>
            <string>#{etc}/docker-lifecycle-listener.d</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>StandardOutPath</key>
          <string>#{var}/log/docker-lifecycle-listener.log</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/docker-lifecycle-listener.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    script_dir=Dir.mktmpdir
    r, w = IO.pipe
    pid = Process.spawn("#{sbin}/docker-lifecycle-listener.sh #{script_dir} 47202", out: w, err: [:child, :out])
    sleep 3
    Process.kill "TERM", pid
    Process.waitpid pid
    w.close

    output = r.read
    r.close

    assert_includes output, "Listening for commands on port 47202"
    assert_includes output, "Stopped"
  end
end
