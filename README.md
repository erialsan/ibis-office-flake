# ibis-office-flake

[ibisOffice](https://github.com/ibisjp/ibis-office) の安定版を、公式リリースタグのソースと Cargo.lock からビルドする非公式 Nix flake です。対象は `x86_64-linux` と `aarch64-linux` です。

## 使い方

```sh
nix build .#ibis-office
nix run .#ibis-office
```

既存の NixOS / Home Manager flake に組み込む場合:

```nix
inputs.ibis-office.url = "github:erialsan/ibis-office-flake";
```

`environment.systemPackages` または `home.packages` に `inputs.ibis-office.packages.${pkgs.stdenv.hostPlatform.system}.ibis-office` を追加します。Cachix のビルドを使う場合は `cachix use CACHE_NAME` を実行し、この input の `nixpkgs` は `follows` で上書きしないでください。上流の更新 PR がマージされたら、利用側で `nix flake update ibis-office` を実行します。

## GitHub Actions の設定

1. 公開の Cachix キャッシュ（Cachix 管理の署名鍵）を作成し、GitHub の **Settings → Secrets and variables → Actions** で変数 `CACHIX_CACHE_NAME` と、書き込み用トークンのシークレット `CACHIX_AUTH_TOKEN` を登録します。[ビルドワークフロー](.github/workflows/build.yml)は PR でもビルドを検証しますが、Cachix への push は既定ブランチでビルドとスモークテストに成功した場合のみ行います。キャッシュ名が未設定ならビルドのみ実行します。
2. **Settings → Actions → General → Workflow permissions** の **Allow GitHub Actions to create and approve pull requests** を有効にします。[更新ワークフロー](.github/workflows/update-release.yml)が 6 時間ごとに最新の正式リリースを確認し、より新しければソースと Cargo 依存のハッシュを計算して [release.json](release.json) の更新 PR を作成または更新します。Actions からの手動実行も可能です。自動マージはしません。
3. `GITHUB_TOKEN` で作成した PR の CI は承認が必要な場合があります。承認なしで起動したい場合は、このリポジトリだけに `Contents: Read and write` と `Pull requests: Read and write` を付与した fine-grained PAT を、任意のシークレット `RELEASE_PR_TOKEN` に設定します。

Dependabot は Nix flake の更新に対応していないため、[Dependabot 設定](.github/dependabot.yml)は GitHub Actions の依存更新を担当し、ibisOffice 本体は上記の更新ワークフローが担当します。Nixpkgs は `nix flake update nixpkgs` で更新できます。

## ソースとライセンス

この flake は [AGPL-3.0](LICENSE) です。ibisOffice 本体は AGPL-3.0-only です。Cachix のバイナリに対応するソースは、そのビルドに使ったこのリポジトリのコミットで `nix build .#ibis-office.src .#ibis-office.cargoDeps` を実行すると取得できます。ビルド手順は [package.nix](package.nix)、上流タグは [release.json](release.json) に記録されています。ライセンスと各種通知はパッケージに同梱しています。