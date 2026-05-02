use std::env;
use std::error::Error;
use std::fs;
use std::path::PathBuf;

pub fn run() -> Result<(), Box<dyn Error>> {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR")?);
    let repo_dir = manifest_dir
        .parent()
        .and_then(|path| path.parent())
        .ok_or("failed to resolve repository root")?
        .to_path_buf();

    let header_path = repo_dir.join("include").join("urngz_cabi.h");
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    let bindgen_out = out_dir.join("urngz_cabi.rs");
    let csharp_out_dir = repo_dir.join("bindings").join("csharp");
    let csharp_out = csharp_out_dir.join("Urngz.NativeMethods.g.cs");

    fs::create_dir_all(&csharp_out_dir)?;

    bindgen::Builder::default()
        .header(header_path.to_string_lossy())
        .allowlist_function("(sfc32|pcg32|jsf32|xoshiro128pp|xoshiro128ss).*")
        .allowlist_type("urngz_.*")
        .layout_tests(false)
        .generate_comments(false)
        .generate()?
        .write_to_file(&bindgen_out)?;

    csbindgen::Builder::default()
        .input_bindgen_file(&bindgen_out)
        .csharp_dll_name("urngz_cabi")
        .csharp_namespace("Urngz")
        .csharp_class_name("NativeMethods")
        .csharp_class_accessibility("public")
        .csharp_use_nint_types(false)
        .always_included_types([
            "urngz_sfc32",
            "urngz_sfc32x16",
            "urngz_pcg32",
            "urngz_pcg32x8",
            "urngz_jsf32",
            "urngz_jsf32x16",
            "urngz_xoshiro128ss",
            "urngz_xoshiro128ssx16",
            "urngz_xoshiro128pp",
            "urngz_xoshiro128ppx16",
        ])
        .generate_csharp_file(&csharp_out)?;

    Ok(())
}
