#!/bin/bash
set -euxo pipefail

parent_dir="$PWD"

local_build=false

if [ "$local_build" = true ]; then
  cd ../comfy
else
  mkdir -p tmp
  if [ ! -d "tmp/comfy" ]; then
    git clone --depth=1 https://github.com/darthdeus/comfy tmp/comfy
  else
    echo "Directory tmp/comfy already exists, skipping clone."
  fi

  cd tmp/comfy
  git pull origin master
fi

mkdir -p target/generated/
mkdir -p target/videos/
mkdir -p target/screenshots/
mkdir -p target/wasm/
rm -rf target/generated/*
rm -rf target/videos/*
rm -rf target/screenshots/*
rm -rf target/wasm/*

mkdir -p "$parent_dir/static/videos/"
mkdir -p "$parent_dir/static/screenshots/"
mkdir -p "$parent_dir/static/wasm/"

date=$(date +"%Y-%m-%d")

template="""
+++
title = \"{{example}}\"
description = \"\"
date = $date

[extra]
screenshot = \"/screenshots/{{example}}.png\"
video = \"/videos/{{example}}.webm\"
gh_source = \"//github.com/darthdeus/comfy/blob/master/comfy/examples/{{example}}.rs\"
wasm_source = \"/wasm/{{example}}/index.html\"
+++

\`\`\`rust
{{code}}
\`\`\`
"""

for example in $(ls comfy/examples | grep -e "\.rs$" | grep -v "custom_config" | grep -v "fragment-shader" | grep -v "exr" | grep -v "fullscreen" | grep -v "spatial_benchmark" | sed "s/\.rs//"); do
  RUSTFLAGS=--cfg=web_sys_unstable_apis cargo build --target wasm32-unknown-unknown --release --example "$example" --features blobs,ldtk,exr
  # cp -r examples/$1/resources target/generated/ || true
  dir="target/generated/$example"
  mkdir -p "$dir"
  cat index.html | sed "s/{{example}}/$example/" > "$dir/index.html"
  wasm-bindgen --out-dir "$dir" --target web "target/wasm32-unknown-unknown/release/examples/$example.wasm"
  code=$(cat "comfy/examples/$example.rs")
  # Use Python to perform the substitution
  result=$(python3 - <<END
template = """${template}"""
code = """${code}"""
example = "$example"
print(template.replace("{{example}}", example).replace("{{code}}", code))
END
)

  echo "$result" > "$parent_dir/content/examples/$example.md"
  # echo "$template" | sed "s/{{example}}/$example/g" | sed "s/{{code}}/$code/" > "$parent_dir/content/examples/$example.md"
done

for example in $(ls comfy/examples | grep -e "\.rs$" | grep -v "custom_config" | grep -v "fragment-shader" | grep -v "exr" | grep -v "fullscreen" | grep -v "spatial_benchmark" | sed "s/\.rs//"); do
  COMFY_DEV_TITLE=1 RUST_BACKTRACE=1 cargo run --example $example --features comfy-wgpu/record-pngs,blobs,ldtk
  cp "target/screenshots/$example.png" "$parent_dir/static/screenshots/$example.png"
  cp "target/videos/$example.webm" "$parent_dir/static/videos/$example.webm"
done

rm -rf "$parent_dir/static/wasm"
cp -R "target/generated/" "$parent_dir/static/wasm/"
