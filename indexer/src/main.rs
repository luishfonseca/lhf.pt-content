use gray_matter::engine::YAML;
use gray_matter::Matter;
use gray_matter::Pod;

fn main() {
    let posts_dir = std::fs::read_dir("content/posts").unwrap_or_else(|_| {
        eprintln!("Couldn't read content/posts directory");
        std::process::exit(1);
    });

    let old_index = std::fs::read_to_string("content/posts.index.txt").unwrap_or_else(|_| {
        eprintln!("Couldn't read content/posts.index.txt");
        std::process::exit(1);
    });

    match index_posts(posts_dir) {
        Ok(posts) => {
            if posts != old_index {
                std::fs::write("content/posts.index.txt", posts).unwrap_or_else(|_| {
                    eprintln!("Couldn't write content/posts.index.txt");
                    std::process::exit(1);
                });
                println!("Updated content/posts.index.txt");
            } else {
                println!("content/posts.index.txt is already up to date");
            }
        }
        Err(err) => eprintln!("{}", err),
    }
}

fn index_posts(dir: std::fs::ReadDir) -> Result<String, String> {
    let mut index = "".to_string();

    let matter = Matter::<YAML>::new();

    for entry in dir {
        let entry = entry.map_err(|err| err.to_string())?;
        let path = entry.path();
        if path.is_dir() {
            let inner_dir = std::fs::read_dir(path).map_err(|err| err.to_string())?;
            index.push_str(&index_posts(inner_dir)?);
        } else {
            if path.extension().unwrap_or_default() == "md" {
                let file = std::fs::read_to_string(path.clone()).map_err(|err| err.to_string())?;

                let data = matter.parse(file.as_str()).data;
                if let Some(Pod::Hash(data)) = data {
                    // Don't index posts with draft: true
                    if let Some(Pod::Boolean(draft)) = data.get("draft") {
                        if draft == &true {
                            continue;
                        }
                    }

                    let path = path
                        .strip_prefix("content/posts/")
                        .map_err(|err| err.to_string())?
                        .to_str()
                        .map_or(Err("invalid path: couldn't convert to str"), |s| Ok(s))?
                        .split('.')
                        .next()
                        .map_or(Err("invalid path: couldn't strip extension"), |s| Ok(s))?;

                    // First index field is the path
                    index.push_str(&path);

                    // Second index field is the slug, if not present generate one from the path
                    index.push(':');
                    if let Some(Pod::String(slug)) = data.get("slug") {
                        index.push_str(&slug);
                    } else {
                        index.push_str(&path.replace("/", "-"));
                    };

                    // Last fields are the tags
                    if let Some(Pod::String(tags)) = data.get("tags") {
                        index.push(':');
                        index.push_str(&tags.replace(" ", ":"));
                    };

                    index.push('\n');
                } else {
                    println!("Invalid front matter in {}", path.to_str().unwrap());
                }
            }
        }
    }

    Ok(index)
}
