class TigerVnc < Formula
  desc "High-performance, platform-neutral implementation of VNC"
  homepage "https://tigervnc.org/"
  url "https://github.com/TigerVNC/tigervnc/archive/v1.10.1.tar.gz"
  sha256 "19fcc80d7d35dd58115262e53cac87d8903180261d94c2a6b0c19224f50b58c4"

  depends_on "cmake" => :build
  depends_on "fltk"
  depends_on "gettext"
  depends_on "gnutls"
  depends_on "jpeg-turbo"
  depends_on :x11

  patch do
    url "https://github.com/XA21X/tigervnc/compare/master...3416598.diff"
    sha256 "a4aac8ca9dd6e62711ff66bd63b29e37ae1ddd4e9e359cfc1a37549809992c24"
  end

  def install
    turbo = Formula["jpeg-turbo"]
    args = std_cmake_args + %W[
      -DJPEG_INCLUDE_DIR=#{turbo.include}
      -DJPEG_LIBRARY=#{turbo.lib}/libjpeg.dylib
      .
    ]
    system "cmake", *args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/vncviewer -h 2>&1", 1)
    assert_match "TigerVNC Viewer 64-bit v#{version}", output
  end
end
