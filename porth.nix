{ lib
, fetchFromGitLab
, stdenvNoCC
, nasm
, fasm
, python3
, stdenv
,
}:
let
  fetchPorth =
    { rev
    , hash ? ""
    ,
    }:
    fetchFromGitLab {
      owner = "tsoding";
      repo = "porth";
      inherit rev hash;
    };

  porthStage0 = stdenv.mkDerivation {
    pname = "porth";
    version = "stage0";

    # Last commit before 8d8abee7304f8e200c680ce3f2bf9beccd308cd5 * Remove porth.py
    src = fetchPorth {
      rev = "7732737c6ae461574fc7d77a67ca69b711151274";
      hash = "sha256-8r5sC7Ptw8D1GRp3Vtx5b1kjAkAIs74dsqG3ccPw4sg=";
    };

    propagatedBuildInputs = [
      python3
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/{bin,lib}"
      cp -r "$src"/* "$out"/.
      install -Dm755 "$out"/porth.py "$out"/bin/porth
      cp -r std "$out"/lib/

      runHook postInstall
    '';
  };

  buildPorthApplication =
    { src
    , main
    , porthCompiler ? porth
    , binName ? lib.strings.removeSuffix ".porth" main
    , useCompilerStd ? true
    , exportStd ? false
    , nativeBuildInputs ? [ ]
    , ...
    } @ args:
    stdenv.mkDerivation (finalAttrs:
    args
    // {
      nativeBuildInputs =
        [
          porthCompiler
          nasm
          fasm
        ]
        ++ nativeBuildInputs;

      buildPhase = ''
        runHook preBuild

        ${lib.strings.optionalString useCompilerStd "ln -s ${porthCompiler}/lib/std std"}
        porth com ${main}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out"/bin
        mv -v ./${binName} "$out"/bin/${lib.strings.removeSuffix ".porth" main}
        ${lib.strings.optionalString exportStd ''
          mkdir -p "$out"/lib/std
          cp -r std/* "$out"/lib/std/.
        ''}

        runHook postInstall
      '';
    });

  porthStage1_1 = buildPorthApplication {
    pname = "porth";
    version = "stage1_1";

    src = fetchPorth {
      rev = "8d8abee7304f8e200c680ce3f2bf9beccd308cd5";
      hash = "sha256-RG2g2D/u46J5BZcFsDbASdSiKqu77gCy49FHx9iApCU=";
    };

    main = "porth.porth";
    binName = "porth";
    porthCompiler = porthStage0;
    useCompilerStd = false;
    exportStd = true;
  };

  porthStage1_2 = buildPorthApplication {
    pname = "porth";
    version = "stage1_2";

    src = fetchPorth {
      rev = "654ed104969e52a51115820d59c8886160f3cf87";
      hash = "sha256-miyv6pgKEHGLSYsGGsV8ZeZiNwycD75W3P9j1lDDn9I=";
    };
    patches = [ ./add-main.patch ];

    main = "porth.porth";
    binName = "output";
    porthCompiler = porthStage1_1;
    useCompilerStd = false;
    exportStd = true;
  };

  porthStage1_3 = buildPorthApplication {
    pname = "porth";
    version = "stage1_3";

    src = fetchPorth {
      rev = "f14fc328f16494b96f4e02c55c6980f4ae5f89f8";
      hash = "sha256-P5jUBJC7+2H0KhrlbjqTczASXG55bj0YMIjhasjANOA=";
    };

    main = "porth.porth";
    binName = "output";
    porthCompiler = porthStage1_2;
    useCompilerStd = false;
    exportStd = true;
  };

  porthStage1 = buildPorthApplication {
    pname = "porth";
    version = "stage1";

    src = fetchPorth {
      rev = "3a09b70e79c6d5de2de0dffcdc4361670dfe5ae9";
      hash = "sha256-JCEO6m3WiUsXw7agrToLfTo3Ue3eUnRlrrj8l1YEVYk=";
    };
    patches = [ ./dos-newlines.patch ];

    main = "porth.porth";
    binName = "output";
    porthCompiler = porthStage1_3;
    useCompilerStd = false;
    exportStd = true;
  };

  buildPorthCompiler = args:
    let
      prev = buildPorthApplication (args // { version = "${args.version}-bootstrap"; });
    in
    buildPorthApplication (args // { porthCompiler = prev; });

  stages2 = [
    {
      rev = "27f99a016643d5cd81cac17cb34287a2f639586d";
      hash = "sha256-Vf1unV71MmGKUnvGGS51V5/Ddw27dHK6oNugE9iiU2w=";
    }
    {
      rev = "27f99a016643d5cd81cac17cb34287a2f639586d";
      hash = "sha256-Vf1unV71MmGKUnvGGS51V5/Ddw27dHK6oNugE9iiU2w=";
    }
    {
      rev = "0e074c64da17425443815264d92b321f87fb224c";
      hash = "sha256-T2CBRjxEeOeWxOh9WlrUvoBSdQ3Dsmk+Yl5R5QE628Y=";
    }
    {
      rev = "8ae08fe6d9f69914a47f0f81304269f4f1880654";
      hash = "sha256-Z2oAiSPjmDT2fsIJ01PbpfBzI3HNGsYLKgYqRrYtN1Y=";
    }
    {
      rev = "8423acce9a8d1846f585f779bb73a7a039d743a3";
      hash = "sha256-uIEKdB+VFiQtps8z0Tjfl0iyMqiazKrdnT/GImsGKyQ=";
    }
    {
      rev = "176f3319d96165e9fc35b83631ea73031f587ebc";
      hash = "sha256-MzW5KWftI8YTLgmca5ifyLrvU2JGwj3VNlJb3ResgOs=";
    }
    {
      rev = "176f3319d96165e9fc35b83631ea73031f587ebc";
      hash = "sha256-MzW5KWftI8YTLgmca5ifyLrvU2JGwj3VNlJb3ResgOs=";
    }
    {
      rev = "133e78647d79f993a1c1653cbaeb361e2ec73438";
      hash = "sha256-+CkAMcMwafkOlXIvbPQV+lAma0pisLjrJ6Xi9NEodho=";
    }
    {
      rev = "432af482ebccd478da32d8fbb2b911e99f87d047";
      hash = "sha256-21C9Ve/PfvorT70SUaOdF6pRQRjC9SaRAg6FXF/bdLw=";
    }
    {
      rev = "dfeb3cb340620ea8995addf1eae8a55c6d03727f";
      hash = "sha256-jxMOJaEuFgj+hq6ESukkTgwedF31m9QO2rWxeCFsjAo=";
    }
    {
      rev = "c3290073933bb4067339d3bc5550d4d9bf8b12c4";
      hash = "sha256-4lZYpHUKFLufTuMucNiAwK5n3/CzMeh4n/LJVn1m7D0=";
    }
    {
      rev = "d4095557cca4e76c9031e64537f5ee3a125de975";
      hash = "sha256-kN3czOR/84VCECLQHHTeko+z26QHnezWZGOKgva647E=";
    }
  ];

  porthStage2 =
    lib.lists.foldl'
      (prevStage: currState: buildPorthCompiler (currState // { porthCompiler = prevStage; }))
      porthStage1
      (lib.imap1
        (i: src: {
          pname = "porth";
          version = "stage2_${toString i}";
          src = fetchPorth src;
          binName = "porth";
          main = "porth.porth";
          useCompilerStd = false;
          exportStd = true;
        })
        stages2);

  porth = buildPorthApplication {
    pname = "porth";
    version = "1.0";

    src = fetchPorth {
      rev = "d4095557cca4e76c9031e64537f5ee3a125de975";
      hash = "sha256-kN3czOR/84VCECLQHHTeko+z26QHnezWZGOKgva647E=";
    };

    nativeCheckInputs = [
      python3
    ];

    doCheck = true;
    checkPhase = ''
      runHook preCheck

      python test.py run

      runHook postCheck
    '';

    main = "porth.porth";
    porthCompiler = porthStage2;

    useCompilerStd = false;
    exportStd = true;

    meta = with lib; {
      homepage = "https://gitlab.com/tsoding/porth";
      license = licenses.mit;
      mainProgram = "porth";
      description = "Concatenative Programming Language for Computers";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  inherit porth buildPorthApplication;
}
