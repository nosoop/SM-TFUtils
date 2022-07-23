# SourceMod Ninja Project Build Instructions

This project uses the [Ninja Project Template for SourceMod Plugins][].

The following is documentation of build steps required for the repository at the time this
project was generated; the source template may be different in the future.

[Ninja Project Template for SourceMod Plugins]: https://github.com/nosoop/NinjaBuild-SMPlugin

## Prerequisites

A few things are needed for developing with this environment:

- A familiarity with command line tooling.
    - An understanding of calling programs and changing directories will do.
- The ninja build system.
    - It's small, fast, cross-platform, and isn't tied to any particular set of tools.
- Python 3.6 or newer.
    - Used to detect our compiler and write out the build script for ninja.
- A clean copy of the [SourceMod][] compiler.  It should not contain any third-party includes.
    - Which version you'll need depends on the project, but assume latest stable if not
    specified.
    - An untouched compiler directory ensures build consistency by not polluting it with custom
    files &mdash; all non built-in dependencies should be encapsulated in the project
    repository (by adding the dependency as a submodule or copying the include files directly).
    - You only need the `addons/sourcemod/scripting/` directory from the SourceMod package.
    - The scripting directory doesn't need to be in `%PATH%` / `$PATH`; the script provides
    `--spcomp-dir`.  This also allows you to quickly switch between compiler / SourceMod
    versions.
    - Do not add / commit the compiler and core includes into your project; the clean compiler
    can be shared between projects and updated independently from your project.  However, *do*
    add third-party includes into your project.

You only need to install these once, but make sure to skim over the `README.md` in case other
projects using this project template require additional software dependencies.

<details>
<summary>Expand to see instructions for installing dependencies</summary>

1. Install `ninja`.
    - You can download the latest version for Windows / Mac / Linux from the [ninja releases][]
    page and install it into your path.
    - With [Scoop][] on Windows, use `scoop install ninja`.
    - With Debian and Debian-based distributions like Ubuntu, `apt install ninja-build` will get
    you the distro's version, which may be a few versions behind current.  That should be fine
    enough in most cases.
2. Install Python 3.
    - You can download and install it manually from [the official site][Python].
    - With [Scoop][], `scoop install python`.
    - With Debian-based distributions, `apt install python3`.
3. Download the [SourceMod][] compiler.
    - On Linux, both 32- and 64-bit versions of `spcomp` are supported by the build script; you
    do not need to install 32-bit compatibility libraries on your build machine.

</details>

[ninja releases]: https://github.com/ninja-build/ninja/releases
[Python]: https://www.python.org/
[Scoop]: https://scoop.sh/
[SourceMod]: https://www.sourcemod.net/

## Building

The tl;dr is that you should be able to build any git-based project in this format with the
following commands:

    git clone --recurse-submodules ${repo}
    # cd into repo
    python3 configure.py --spcomp-dir ${dir}
    ninja

Detailed explanation:

1. Clone the repository and any git repositories it depends on, then navigate to it.
2. Run `python3 configure.py --spcomp-dir ${dir}` within the project root, where `${dir}` is a
directory containing the SourcePawn compiler (`spcomp`) and SourceMod's base include files.
This will create the `build.ninja` script.
    - You may need to use `python3.8` or some other variant of the executable name, depending on
    your environment.
    - If `--spcomp-dir` isn't specified, the script will try to detect the compiler based on an
    existing `spcomp` executable in your path.
    - Do not add `build.ninja` to version control; it should always be generated from
    `configure.py` as it contains paths specific to your filesystem.  (It's ignored by default,
    but mentioned here for emphasis.)
3. Run `ninja`; this will read the `build.ninja` script and build things as necessary.  Files
will be generated and copied to `build/`, creating any intermediate folders if they don't exist.
Re-run `ninja` whenever you make changes to rebuild any files as necessary.
    - You do not have to re-run `python3 configure.py` yourself; running `ninja` will do this
    for you if `configure.py` itself is modified, and it will pass in the same parameters you
    originally used.  You may want to re-run it yourself if you change the options.
    - Any files removed from `configure.py` will remain in `build/`; run `ninja -t cleandead`
    to remove any lingering outputs.
    - In case you need to wipe the build outputs, delete `build.ninja` and `build/`, then start
    from step 2.
