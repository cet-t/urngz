use std::env;
use std::error::Error;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn Error>> {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR")?);
    let repo_dir = manifest_dir
        .parent()
        .and_then(|path| path.parent())
        .ok_or("failed to resolve repository root")?
        .to_path_buf();

    println!(
        "cargo:rerun-if-changed={}",
        repo_dir.join("include/urngz_cabi.h").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        manifest_dir.join("build.rs").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        manifest_dir.join("src/generate.rs").display()
    );

    Ok(())
}
