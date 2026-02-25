import json

files = [
    ("Default", r"content\assets\source-external\infra-terraform\assets\blueprint.json"),
    ("Data Science", r"content\assets\source-external\infra-terraform\assets\blueprint-data-science\blueprint.json"),
    ("Software Engineering", r"content\assets\source-external\infra-terraform\assets\blueprint-software-engineering\blueprint.json")
]

with open("temp.txt", "w", encoding="utf-8") as out:
    for name, path in files:
        out.write(f"=== {name} ===\n")
        try:
            with open(path, encoding="utf-8") as f:
                d = json.load(f)
            
            for g in d.get("host_groups", []):
                comps = [c["name"] for c in g.get("components", [])]
                out.write(f"{g['name']}: {', '.join(comps)}\n")
        except Exception as e:
            out.write(f"Error reading {path}: {e}\n")
        out.write("\n")
