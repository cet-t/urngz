mod generate;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    generate::run()
}
