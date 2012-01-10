# Ruby Christmas Contest.

Ce code représente ma solution au problème posé lors du concours. La page officielle du concours ce trouve ici : [http://contest.dimelo.com/](http://contest.dimelo.com/).

Pour des raison de pérennité, je reproduit ici les détails du problème.

## Les données de départs
Le programme démarrera avec ces données constantes correspondant à un sous-ensemble de données d'un profil github (celui de Defunkt). C'est sur ces données que devront s'appliquer les règles et l'execution des règles fournira un score utilisateur. Il n'y a donc rien de spécial à faire au niveau programmation à ce niveau, juste à utiliser le profil test ci-dessous.

### Les données du profil
Les données du hash correspondent à un profil github, voici le détail des clés :

 - login `String` : Nom du profil (pour info)
 - followers `Fixnum` : Nombre de followers du profil
 - commits `Fixnum` : Nombre de commits effectué par le profil
 - repositories `Array` : Tableau de project ayant chacun un name de type string (pour info) et 2 attributs de type Fixnum watchers et forks

### Données du profil

Voilà la constante de profil sur laquelle seront appliquée les règles, la seule partie dynamique du programme sera donc de lire, parser et executer le fichier de règles. Le reste (comme ici le profil) est statique


      {
        "login" => "defunkt",
        "followers" => 4674,
        "commits" => 8901,
        "repositories" => [
                            {
                              "watchers" => 79,
                              "forks" => 9,
                              "name" => "choice"
                            },
                            {
                              "watchers" => 28,
                              "forks" => 1,
                              "name" => "mapreducerb"
                            },
                            {
                              "watchers" => 16,
                              "forks" => 3,
                              "name" => "ambitious_activerecord"
                            },
                            {
                              "watchers" => 151,
                              "forks" => 39,
                              "name" => "emacs"
                            },
                            {
                              "watchers" => 787,
                              "forks" => 116,
                              "name" => "github-gem"
                            },
                            {
                              "watchers" => 1559,
                              "forks" => 298,
                              "name" => "facebox"
                            },
                            {
                              "watchers" => 2977,
                              "forks" => 425,
                              "name" => "resque"
                            } 
                          ]
      }
      
## Le moteur de règle

On attaque le coeur du défi et la partie à réaliser, c'est à dire le parser de règle et l'exécuteur des règles sur les données. Les règles sont de simples instructions dans un fichier texte dont la syntaxe est précisée ci-dessous et qui s'appliquent aux attributs du profil followers, commits et repositories. Ces règles précisent le nombre de point à attribuer pour chaque attribut du profil. Pour corser le problème, au niveau des repositories les règles peuvent être conditionnées sur les valeurs des attributs du repository (le nombre de forks et de watchers). Et finalement ces règles ne sont pas forcement mutuellement exclusives sur le principe de la dernière règle qui s'applique écrase les autres, elles peuvent être additives si l'opérateur adéquat est utilisé. Toute règle non définie sur un attribut du profil est à 0 (pas de point attribués par défaut). Commençons donc par quelques exemples.

### Cas simple

Le fichier contient une règle simple pour chacun des attributs, en l'occurrence 1 point par follower, 1 point par commit et 1 point par repository


        commit = 1
        repository = 1
        follower = 1

      
Résultat: En l'occurrence le score de l'utilisateur sera donc égal à followers + repositories.size + commits.

### Cas conditionnel

Les conditions ne concernent que les attributs de repository et donc que les points attribués aux repositories. Les opérateur de comparaison à supporter sont > et < qui ont le même sens qu'en ruby. L'opérateur s'applique avec à gauche un attribut de repository et à droite un entier. On peut combiner les conditions juste avec l'opérateur && qui correspond à l'opérateur logique AND. Les conditions sont executées au runtime avant les affectations (comme en ruby), si la condition est fausse l'affectation est ignorées. Quand plusieurs affectation par l'opérateur = sont executées successivement, seule la dernière affectation est conservée (comme pour l'affectation de variable). La logique d'execution des règles est ici similaire à du code ruby.

    
        repository = 1
        repository = 5 if repository.watchers > 10
        repository = 5 if repository.forks > 10
        repository = 20 if repository.watchers > 10 && repository.forks > 10

      
Résultat: Dans ce cas les commits et les followers ne rapportent pas de point (à 0 par défaut) et chaque repository rapporte 1 points s'il a moins de 11 watchers et forks, 5 points si il a plus de 10 watchers OU plus de 10 forks et 20 points si il a plus de 10 watchers ET plus de 10 forks.

### Cas d'additivité

Jusque-là chaque définition d'attribution de point écrasait la précédante à partir du moment où elle s'executait (les conditions, si il y en avait, étaient remplies). Il existe un autre opérateur d'affection += qui permet d'ajouter des points à l'affectation existante plutôt que de la remplacer. Cela fonctionne comme l'opérateur += en ruby.


        commit = 1
        commit = 2
        commit += 3
        follower = 1
        follower += 2
        follower = 5
        repository += 5

      
Résultat: Ici on est dans le cas où on attribut 5 points par commit, par follower et par repository. L'arythmétique en jeu est identique à de l'affectation de variable en ruby, l'affectation remplace la valeur précédante et l'affectation additive affecte au registre la valeur "ancienne valeur + nouvelle valeur". Le seul cas un peu spécial ici est le cas de repository qui affecte 5 à la valeur par defaut (zéro), ce qui donne donc 5 au final.

### Cas complet

Exemple d'un cas avec les opérateurs d'affectation et les conditions en même temps.


        follower = 2
        repository = 5
        repository = 1 if repository.watchers  < 2 && repository.forks < 2
        repository += 10 if repository.watchers  > 10
        repository += 10 if repository.forks  >  10
        repository = 50 if repository.watchers  > 100 && repository.forks > 100

      
Résultat: C'est le cas le plus complet que l'on puisse avoir, les commits rapportent 0, les followers rapportent 2 points, et au niveau des repositories ceux qui ont moins de 2 watchers ET forks rapportent 1 points sinon la valeur de base est 5 point. Si en plus le repository a plus de 10 watchers on gagne un bonus de 10 points, pareil pour les forks. Si en plus à la fois les watchers et les forks dépassent 100 alors le reposity rapporte 50 points en tout.

## Récapitulatif des opérateurs et opérandes

 - `repository`, `follower`, `commit` : Registre de point. Ces registres définisse la valeur en point de l'object courant
 - `=`, `+=` : Operateur d'affectation. Réaffecte ou affecte additivement un entier à un registre
 - `\d+` : Fixnum. Valeur constante pouvant être affectée à un registre ou comparée à un attribut
 - `repository.watchers`, `repository.forks` : Attribut de l'object repository courant (s'il y en a). Ces attributs ont une valeur courante qui est un entier et peuvent être comparé à des Fixnum
 - `>`, `<` : Opérateur de comparaison. Compare un attribut de l'object repository à un entier (le résultat de l'opération vaut vrai ou faux)
 - `&&` : Opérateur de logique AND. Permet de combiner des opérations de comparaison
 - `if` : Opérateur conditionel. Execute la règle si et seulement si la condition est vraie, sinon la règle est ignorée

## Packaging de la solution

La solution devra être un executable ruby, avec le shebang #!/usr/bin/env ruby, si il y a des Gem dont vous dépendez elles devront être gérée avec un Gemfile et le code devra tourner sur 1.8.7 MRI ou 1.9.3 MRI (.rvmrc à fournir dans ce cas là). Aucune autre dépendance que des gems, les libs de developments ruby et un compilateur C ne sont acceptées.

L'executable ne prendra qu'un seul paramètre le chemin absolu du fichier de règle et devra en STDOUT renvoyer la valeur du score. Exemple:


        $ ./ruby-contest ./test-rules.txt
        1250

      
Les choix d'implémentation de la solution sont libres, DSL ruby, parser/lexer, peg/leg, regexp, à la mano, toutes les solutions sont acceptables même si certaines sont plus élégantes et extensibles que d'autres. Le gagnant officiel sera déterminé via les règles.