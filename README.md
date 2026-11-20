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

`environment.systemPackages` または `home.packages` に `inputs.ibis-office.packages.${pkgs.stdenv.hostPlatform.system}.ibis-office` を追加します。[Cachix の公開キャッシュ](https://app.cachix.org/cache/erialsan)を利用する場合は `cachix use erialsan` を実行するか、NixOS の設定に次を追加してください。

```nix
nix.settings = {
  extra-substituters = [ "https://erialsan.cachix.org" ];
  extra-trusted-public-keys = [
    "erialsan.cachix.org-1:TCJo1GXMp1biAoY2SaghfNK7W4kXGvymlJmJ4cIPNG4="
  ];
};
```

キャッシュを利用するには、この input の `nixpkgs` を `follows` で上書きしないでください。上流の更新 PR がマージされたら、利用側で `nix flake update ibis-office` を実行します。

## GitHub Actions の設定

1. `erialsan/ibis-office-flake` の配信先は `erialsan` です。GitHub の **Settings → Secrets and variables → Actions** で書き込み用トークンをシークレット `CACHIX_AUTH_TOKEN` に登録します。[ビルドワークフロー](.github/workflows/build.yml)は PR でもビルドを検証しますが、Cachix への push は既定ブランチでビルドとスモークテストに成功した場合のみ行います。フォークでは `CACHIX_CACHE_NAME` が未設定ならビルドのみ実行します。独自キャッシュへ配信するには、その名前と `CACHIX_AUTH_TOKEN` を設定してください。
2. **Settings → Actions → General → Workflow permissions** の **Allow GitHub Actions to create and approve pull requests** を有効にします。[更新ワークフロー](.github/workflows/update-release.yml)が 6 時間ごとに最新の正式リリースを確認し、より新しければソースと Cargo 依存のハッシュを計算して [release.json](release.json) の更新 PR を作成または更新します。Actions からの手動実行も可能です。自動マージはしません。
3. `GITHUB_TOKEN` で作成した PR の CI は承認が必要な場合があります。承認なしで起動したい場合は、このリポジトリだけに `Contents: Read and write` と `Pull requests: Read and write` を付与した fine-grained PAT を、任意のシークレット `RELEASE_PR_TOKEN` に設定します。

Dependabot は Nix flake の更新に対応していないため、[Dependabot 設定](.github/dependabot.yml)は GitHub Actions の依存更新を担当し、ibisOffice 本体は上記の更新ワークフローが担当します。Nixpkgs は `nix flake update nixpkgs` で更新できます。

## ソースとライセンス

この flake は [AGPL-3.0](LICENSE) です。ibisOffice 本体は AGPL-3.0-only です。Cachix のバイナリに対応するソースは、そのビルドに使ったこのリポジトリのコミットで `nix build .#ibis-office.src .#ibis-office.cargoDeps` を実行すると取得できます。ビルド手順は [package.nix](package.nix)、上流タグは [release.json](release.json) に記録されています。ライセンスと各種通知はパッケージに同梱しています。