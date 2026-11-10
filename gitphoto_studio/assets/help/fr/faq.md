# Questions fréquentes

## Mes photos d'origine sont-elles modifiées ?

Non. L'application travaille sur des copies. Optimiser, convertir, renommer ou retirer de la bibliothèque n'affecte jamais vos fichiers d'origine.

## Faut-il connaître Git ?

Non. L'application crée les commits pour vous et vérifie le résultat. Les rubriques [Commits](help:commits) et [Branches](help:branches) expliquent les notions si vous êtes curieux.

## Puis-je publier sans Internet ?

Non, mais vous pouvez préparer vos médias hors ligne. Une publication confirmée attend dans la file et part dès que la connexion revient (application ouverte).

## Une photo a été publiée deux fois ?

C'est évité : un fichier identique déjà présent à cet emplacement est ignoré, et une même publication ne peut pas être mise deux fois en file. Si un fichier différent porte le même nom, le vôtre est renommé.

## Comment supprimer une photo publiée sur GitHub ?

L'application ne supprime jamais rien sur GitHub. Faites-le sur github.com (ouvrir le fichier › menu › **Delete file**). L'ancienne version restera dans l'historique Git.

## Pourquoi un dépôt privé ?

Seuls vous et les personnes invitées y ont accès. Un dépôt public est visible par tout le monde, y compris les métadonnées des photos.

## Le jeton expire, que faire ?

Créez-en un nouveau sur GitHub, puis reconnectez-vous dans l'écran GitHub. Les publications en attente reprendront.

## L'IA est-elle obligatoire ?

Non. Elle est désactivée par défaut et toutes les fonctions marchent sans elle.

## Combien coûte l'agent IA ?

L'application est gratuite ; les fournisseurs d'IA en ligne facturent généralement à l'usage, sur votre compte chez eux. Ollama, en local, est gratuit.

## Pourquoi la conversion vidéo n'est-elle pas proposée ?

Sous Linux, installez ffmpeg (`sudo apt install ffmpeg`) puis actualisez **Paramètres › Diagnostic**.

## Quelle taille maximale ?

Jusqu'à 50 Mio par l'API GitHub ; de 50 Mio à 2 Gio par Git LFS (quota de votre compte) ; au-delà, refusé.

## Où trouver plus d'aide ?

Cherchez un mot dans le [sommaire](app:/help) du mode d'emploi, ou copiez le rapport de diagnostic (**Paramètres › Diagnostic**) pour le joindre à une demande d'aide.
