1. Introduction

Ce projet implémente quatre algorithmes de recherche de chemin : BFS, Dijkstra, A* (Arrivée*)
et Glouton. Le terrain est chargé depuis un fichier .map (ou .txt) à partir de la 5ème ligne. La grille
est constituée de cases normales (représentées par ’.’) et d’obstacles (représentés par ’@’, ’T’, ’S’ et
’W’). Chaque algorithme vérifie que les points de départ et d’arrivée ne se trouvent pas sur un obstacle,
puis calcule un chemin (optimal pour BFS, Dijkstra et A* ; approché pour l’algorithme glouton).
Remarque sur l’affichage : Bien que le chemin soit correctement calculé, l’affichage console ne reflète
pas fidèlement la structure du terrain en raison du wrapping automatique des lignes par le terminal.
C’est pourquoi le résultat est sauvegardé dans un fichier texte, offrant ainsi une représentation fidèle
du chemin.
2. Installation et Configuration

— Dépendances : Aucune bibliothèque externe n’est requise pour le fonctionnement de base, sauf
pour l’affichage coloré en console si vous souhaitez utiliser printstyled (disponible dans certains
environnements).
— Configuration du fichier d’entrée : Le fichier d’entrée doit être au format .map ou .txt et
contenir le terrain à partir de la 5ème ligne. Veillez à ce que les lignes soient de longueur identique
pour un affichage correct.

3. Utilisation
Les fonctions d’algorithmes sont conçues pour être appelées directement depuis la REPL ou via
un script, par exemple :
algoAstar("battleground.map", (12, 25), (25, 65))
De même, les autres algorithmes (BFS, Dijkstra, Glouton) peuvent être appelés en fournissant directement le nom du fichier et les coordonnées de départ et d’arrivée sous forme de tuples. Aucune variable
globale n’est requise, ce qui élimine le risque d’erreur UndefVarError que j’ai rencontrée plusieurs fois
lors de la programmation du code.
