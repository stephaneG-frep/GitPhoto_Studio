#!/usr/bin/env python3
"""Génère les guides de docs/ à partir des rubriques du mode d'emploi
intégré (assets/help/fr/), pour qu'il n'existe qu'une seule source.

Usage : python3 scripts/generate_guides.py          (écrit les fichiers)
        python3 scripts/generate_guides.py --check  (vérifie qu'ils sont à jour)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
HELP = ROOT / "assets" / "help" / "fr"

# Ordre du sommaire (identique à HelpTopic dans l'application).
ORDER = [
    "premiers-pas", "connexion-github", "creer-depot", "publier-photo",
    "publier-video", "optimiser-organiser", "commits", "branches", "git-lfs",
    "historique-reprise", "agent-ia", "fournisseurs-ia", "erreurs",
    "confidentialite", "faq", "glossaire",
]

GUIDES = {
    "MODE_EMPLOI.md": ("Mode d'emploi — GitPhoto Studio IA", ORDER),
    "GUIDE_GITHUB.md": ("Guide de configuration GitHub", [
        "connexion-github", "creer-depot", "publier-photo", "branches",
        "git-lfs", "historique-reprise",
    ]),
    "GUIDE_IA.md": ("Guide des fournisseurs IA", [
        "fournisseurs-ia", "agent-ia", "confidentialite",
    ]),
}

LINK = re.compile(r"\[([^\]]+)\]\((?:app|help):[^)]*\)")


def topic(name: str) -> str:
    text = (HELP / f"{name}.md").read_text(encoding="utf-8")
    text = LINK.sub(r"\1", text)  # liens internes à l'application
    # Les titres descendent d'un niveau sous le titre du guide.
    return re.sub(r"^(#{1,5}) ", r"#\1 ", text, flags=re.M).strip()


def build(title: str, names: list[str]) -> str:
    head = (
        f"# {title}\n\n"
        "> Document généré par `scripts/generate_guides.py` à partir du mode "
        "d'emploi intégré à l'application (Mode d'emploi). Ne pas modifier à "
        "la main : modifier `assets/help/fr/` puis relancer le script.\n"
    )
    return head + "\n" + "\n\n".join(topic(n) for n in names) + "\n"


def main() -> int:
    check = "--check" in sys.argv
    stale = []
    for file, (title, names) in GUIDES.items():
        path = ROOT / "docs" / file
        content = build(title, names)
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(file)
        else:
            path.write_text(content, encoding="utf-8")
            print(f"écrit : docs/{file}")
    if stale:
        print("À régénérer : " + ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
