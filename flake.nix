{
  description = "Flutter 3.19.x";
  inputs = {
    nixpkgs.url = "https://mirrors.ustc.edu.cn/nix-channels/nixos-24.05/nixexprs.tar.xz";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion "30.0.3" ];
          platformVersions = [ "28" "29" "30" "31" "33" "34" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          includeNDK = true;
          ndkVersions = ["21.4.7075529"];
          cmakeVersions = [ "3.18.1" ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs; mkShell rec {
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2"; # 30.0.3  34.0.0
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            JAVA_HOME = "${pkgs.jdk17.home}";
            CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
            buildInputs = [
              flutter # flutter=3.19 flutter316  flutter313
              androidSdk # The customized SDK that we've made above
              gradle #Gradle=8.6 gradle_7 gradle_6
              jdk17
              fish
              chromium
            ];
            shellHook = ''
              echo ${androidSdk}
            '';
          };
      });
}