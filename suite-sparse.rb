require 'formula'

class SuiteSparse < Formula
  homepage 'http://www.cise.ufl.edu/research/sparse/SuiteSparse'
  url 'http://www.cise.ufl.edu/research/sparse/SuiteSparse/SuiteSparse-4.0.0.tar.gz'
  md5 'a63acb2f52649dd625737b92bda675f9'

  depends_on "metis"
  depends_on "tbb"

  def install
    # SuiteSparse doesn't like to build in parallel
    ENV.j1

    # So, SuiteSparse was written by a scientific researcher.  This
    # tends to result in makefile-based build systems that are completely
    # ignorant of the existence of things such as CPPFLAGS and LDFLAGS.
    # SuiteSparse Does The Right Thing™ when homebrew is in /usr/local
    # but if it is not, we have to piggyback some stuff in on CFLAGS.
    unless HOMEBREW_PREFIX.to_s == '/usr/local'
      ENV['CFLAGS'] += " -isystem #{HOMEBREW_PREFIX}/include -L#{HOMEBREW_PREFIX}/lib"
    end

    # Some of the suite-sparse libraries use Metis
    metis = Formula.factory("metis")

    inreplace 'SuiteSparse_config/SuiteSparse_config.mk' do |s|
      # Libraries
      s.change_make_var! "BLAS", "-Wl,-framework -Wl,Accelerate"
      s.change_make_var! "LAPACK", "$(BLAS)"
      s.remove_make_var! "METIS_PATH"
      s.change_make_var! "METIS", metis.lib + 'libmetis.a'
      s.change_make_var! "SPQR_CONFIG", "-DHAVE_TBB"
      s.change_make_var! "TBB", "-ltbb"

      # Installation
      s.change_make_var! "INSTALL_LIB", lib
      s.change_make_var! "INSTALL_INCLUDE", include
    end

    system "make library"

    lib.mkpath
    include.mkpath
    system "make install"
  end

  def patches
    # This patch renames all "idxtype" variables to "idx_t"
    "https://raw.github.com/gist/3101831/f9b20f278d668df289575e004832234da398e5aa/gistfile1.txt"
  end
end
