class Tree < Formula
  desc "Display directories as trees (with optional color/HTML output)"
  homepage "https://oldmanprogrammer.net/source.php?dir=projects/tree"
  url "https://github.com/Old-Man-Programmer/tree/archive/refs/tags/2.3.2.tar.gz"
  sha256 "22cf32e84e3eb508d97a9e991c2c3cc006b9dcf4afed201d96311c5c57d08fcf"
  license "GPL-2.0-or-later"
  compatibility_version 1

  bottle do
    root_url "https://github.com/sevaiam/homebrew-ventura/releases/download/tree-2.3.2"
    sha256 cellar: :any_skip_relocation, ventura: "60f0520ea31f96dd3ec4334683cef1fadf93a5eec26dbad6065ec6e00b89e3c1"
  end

  deny_network_access!

  def install
    system "make", "install", "PREFIX=#{prefix}", "MANDIR=#{man}"
  end

  test do
    system bin/"tree", prefix
  end
end
