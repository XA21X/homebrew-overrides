class DockerEtcHosts < Formula
  desc "Adds entries to /etc/hosts to allow addressing containers by name"
  homepage "https://github.com/Mahoney/docker-etc-hosts"
  url "https://github.com/Mahoney/docker-etc-hosts/archive/0.2.0.tar.gz"
  sha256 "8cd8a6907be9d28cddbfc180001a8ad2ea312934b77810824037b96bcbbfe35f"
  license "AGPL-3.0-or-later"

  bottle :unneeded

  depends_on "bash"
  depends_on "coreutils"
  depends_on "docker-lifecycle-listener"

  def install
    sbin.install "docker-etc-hosts.sh"

    on_start_dir = etc/"docker-lifecycle-listener.d/on_start"
    begin
      on_start_dir.install_symlink opt_sbin/"docker-etc-hosts.sh"
    rescue
      puts <<~EOS
        Unable to link into #{on_start_dir}; you must do this manually:
          sudo ln -sf #{opt_sbin}/docker-etc-hosts.sh #{on_start_dir}/
      EOS
    end
  end

  def caveats
    <<~EOS
      You must manually make root own the scripts:
        sudo chown root #{sbin}/docker-etc-hosts.sh
    EOS
  end

  test do
    system "true"
  end
end
