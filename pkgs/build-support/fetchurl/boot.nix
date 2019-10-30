let mirrors = import ./mirrors.nix; in

{ system }:

{ url ? builtins.head urls
, urls ? []
, hash ? "" # an SRI hash

# Legacy hash specification
, sha1 ? "", sha256 ? "", sha512 ? ""
, outputHash ?
    if hash != "" then hash else if sha512 != "" then sha512 else if sha1 != "" then sha1 else sha256
, outputHashAlgo ?
    if hash != "" then "" else if sha512 != "" then "sha512" else if sha1 != "" then "sha1" else "sha256"
, name ? baseNameOf (toString url)
}:

let
  hash_ =
    if hash != "" then { outputHashAlgo = null; outputHash = hash; }
    else if (outputHash != "" && outputHashAlgo != "") then { inherit outputHashAlgo outputHash; }
    else if sha512 != "" then { outputHashAlgo = "sha512"; outputHash = sha512; }
    else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
    else if sha1   != "" then { outputHashAlgo = "sha1";   outputHash = sha1; }
    else throw "fetchurlBoot requires a hash for fixed-output derivation: ${url}";
in

import <nix/fetchurl.nix> {
  inherit system name;
  inherit (hash_) outputHash outputHashAlgo;

  url =
    # Handle mirror:// URIs. Since <nix/fetchurl.nix> currently
    # supports only one URI, use the first listed mirror.
    let m = builtins.match "mirror://([a-z]+)/(.*)" url; in
    if m == null then url
    else builtins.head (mirrors.${builtins.elemAt m 0}) + (builtins.elemAt m 1);
}
