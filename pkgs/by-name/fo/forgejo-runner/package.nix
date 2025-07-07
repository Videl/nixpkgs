{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitea,
  nixosTests,
  versionCheckHook,
  nix-update-script,
}:

let
  # tests which assume network access in some form
  disabledTests = [
    "Test_runCreateRunnerFile"
    "Test_ping"
  ];
in
buildGoModule rec {
  pname = "forgejo-runner";
  version = "7.0.0";

  src = fetchFromGitea {
    domain = "code.forgejo.org";
    owner = "forgejo";
    repo = "runner";
    rev = "v${version}";
    hash = "sha256-vt0uPGJdydy4cM1AEBeXQu4aNRggqaITS3eAmimVPRU=";
  };

  vendorHash = "sha256-hE03QkXSPyl7IVEnXi/wWwQZOVcdyyGdEmGiOwLK6Zg=";

  ldflags = [
    "-s"
    "-w"
    "-X gitea.com/gitea/act_runner/internal/pkg/ver.version=${src.rev}"
  ];

  checkFlags = [
    "-skip ${lib.concatStringsSep "|" disabledTests}"
  ];

  doInstallCheck = false;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/${meta.mainProgram}";
  versionCheckProgramArg = "--version";

  passthru = {
    updateScript = nix-update-script { };
    tests = lib.optionalAttrs stdenv.hostPlatform.isLinux {
      sqlite3 = nixosTests.forgejo.sqlite3;
    };
  };

  preInstall = ''
    mv "$GOPATH/bin/runner.forgejo.org" "$GOPATH/bin/act_runner"
  '';

  meta = with lib; {
    description = "Runner for Forgejo based on act";
    homepage = "https://code.forgejo.org/forgejo/runner";
    changelog = "https://code.forgejo.org/forgejo/runner/src/tag/${src.rev}/RELEASE-NOTES.md";
    license = licenses.mit;
    maintainers = with maintainers; [
      adamcstephens
      emilylange
      christoph-heiss
    ];
    mainProgram = "act_runner";
  };
}
