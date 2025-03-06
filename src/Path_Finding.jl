# --------------------------------------------------------------------------------------------------
# Programme qui implémente quatre algorithmes de recherche de chemin (BFS, Dijkstra, A* et Glouton)
# Le terrain est lu depuis un fichier .map ou .txt à partir de la 5ème ligne.
# Le terrain est composé de cases normales ('.') et d'obstacles ('@','T','S','W').
# Le programme vérifie que les points de départ et d'arrivée ne se trouvent pas sur un obstacle.
# Le chemin trouvé est affiché dans la console en remplaçant les cases du chemin par '*'
# (en orange), avec le départ représenté par 'D' (en vert) et l'arrivée par 'A' (en rouge).

# --------------------------------------------------------------------------------------------------
# Fonction pour charger le terrain depuis un fichier .map ou .txt en lisant à partir de la 5ème ligne
function chargerFichier(nom_fichier::String)
    # Vérifie que le fichier a l'extension .map
    if !endswith(nom_fichier, ".map" ) || endswith(nom_fichier, ".txt")
        error("Le fichier doit être de type .map ou .txt")  #  Erreur si l'extension n'est pas ".map" ou ".txt"
    end
    # Vérifie que le fichier existe
    if !isfile(nom_fichier)
        error("Le fichier \"$nom_fichier\" n'existe pas.")  # Erreur si le fichier n'existe pas
    end
    # Lire toutes les lignes du fichier
    all_lines = readlines(nom_fichier)  # Lit toutes les lignes du fichier dans un tableau
    # S'assurer qu'il y a au moins 5 lignes dans le fichier
    if length(all_lines) < 5
        error("Le fichier \"$nom_fichier\" ne contient pas assez de lignes pour être lu à partir de la 5ème ligne.")
    end
    # Ne conserver que les lignes à partir de la 5ème ligne (ignorer les 4 premières)
    lines = all_lines[5:end]  # Extrait le sous-tableau des lignes depuis la 5ème jusqu'à la fin
    # Construire la grille en transformant chaque ligne en un tableau de caractères
    grille = [collect(line) for line in lines]  # Chaque ligne devient un tableau de caractères
    return grille  # Retourne la grille comme un tableau 2D de caractères
end

# --------------------------------------------------------------------------------------------------
# Fonction pour vérifier si une coordonnée est dans les limites de la grille
function isValidCoordinate(coordonnees::Tuple{Int64, Int64}, grille)
    i, j = coordonnees  # Décomposer le tuple en ligne (i) et colonne (j)
    # Retourne vrai si i et j sont dans les limites (i entre 1 et nombre de lignes, j entre 1 et nombre de colonnes)
    return i ≥ 1 && i ≤ length(grille) && j ≥ 1 && j ≤ length(grille[1])
end

# --------------------------------------------------------------------------------------------------
# Fonction pour calculer le coût du mouvement en fonction de la valeur de la case
function cout_mouvement(case::Char)::Int
    if case == 'T'
        # 'T' représente un arbre (tree) et son coût de déplacement est 3
        return 3
    elseif case == 'S'
        # 'S' représente le sable (sand) et son coût de déplacement est 5
        return 5
    elseif case == 'W'
        # 'W' représente l'eau (water) et son coût de déplacement est 8
        return 8
    elseif case == '@'
        # '@' représente un obstacle particulier et son coût de déplacement est 10
        return 10
    else
        # Pour toute autre case (par exemple une case normale '.'), le coût par défaut est 1
        return 1
    end
end

# --------------------------------------------------------------------------------------------------
# Fonction pour obtenir les voisins d'une case 
function get_voisins(coordonnees::Tuple{Int64, Int64}, grille)
    x, y = coordonnees  # Récupère la position actuelle : x correspond à la ligne et y à la colonne
    voisins = Tuple{Int64, Int64}[]  # Initialise un tableau vide pour stocker les coordonnées voisines
    directions = [(-1, 0), (1, 0), (0, -1), (0, 1)] # Défini les directions possibles 
    for d in directions  # Pour chaque direction possible
        # NOTE : Ici, on utilise par erreur les variables 'i' et 'j' au lieu de 'x' et 'y'
        new_x = x + d[1] # Calcul de la nouvelle ligne 
        new_y = y + d[2] # Calcul de la nouvelle colonne 
        # Vérifie si les nouvelles coordonnées (new_x, new_y) sont valides dans la grille
        if isValidCoordinate((new_x, new_y), grille)
            push!(voisins, (new_x, new_y))  # Ajoute la coordonnée voisine à la liste
        end
    end
    return voisins  # Retourne le tableau des voisins valides
end

# --------------------------------------------------------------------------------------------------
# Fonction pour afficher sur la console le terrain avec le chemin trouvé en couleur.
# Le chemin est représenté par '*' (en orange), le départ par 'S' (en vert) et l'arrivée par 'G' (en rouge).
# Les coordonnées de départ et d'arrivée sont affichées en cyan.
function affichage_console(grille, chemin, depart::Tuple{Int64,Int64}, arrivee::Tuple{Int64,Int64})
    # Crée une copie de la grille pour ne pas modifier l'original
    grid_copy = deepcopy(grille)
    
    # Remplace les cases du chemin par '*'
    for (i, j) in chemin
        grid_copy[i][j] = '*'
    end
    
    grid_copy[depart[1]][depart[2]] = 'D'
    grid_copy[arrivee[1]][arrivee[2]] = 'A'
    
    
    # Affiche les coordonnées de départ et d'arrivée en cyan et en gras
    printstyled("Coordonnées de départ: $(depart) | Coordonnées d'arrivée: $(arrivee)\n", color=:cyan, bold=true)
    println("Représentation du chemin sur le terrain :")
    
    for row in grid_copy  # Parcourt chaque ligne de la grille copiée
        for case in row  # Parcourt chaque case de la ligne
            if case == '*'
                printstyled(case, color=:yellow, bold=true)  # Affiche le chemin en orange et en gras
            elseif case == 'D'
                printstyled(case, color=:green, bold=true)  # Affiche le point de départ en vert et en gras
            elseif case == 'A'
                printstyled(case, color=:red, bold=true)  # Affiche le point d'arrivée en rouge et en gras
            else
                print(case)  # Affiche les autres cases sans style particulier
            end
        end
        println()  # Retour à la ligne après chaque rangée
    end
end

# --------------------------------------------------------------------------------------------------
# Implémentation de l'algorithme BFS (Breadth First Search) pour la recherche de chemin
function algoBFS(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64})
    grille = chargerFichier(nom_fichier)  # Charger le terrain depuis le fichier .map
    if !isValidCoordinate(depart, grille)  # Vérifie que la coordonnée de départ est valide
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)  # Vérifie que la coordonnée d'arrivée est valide
        error("Le point d'arrivée $arrivee est invalide.")
    end
    # Vérifie que le point de départ ne se trouve pas sur un obstacle
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    # Vérifie que le point d'arrivée ne se trouve pas sur un obstacle
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W'] 
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end
    
    queue = [depart]  # Initialise la file d'attente avec le point de départ
    parents = Dict{Tuple{Int, Int}, Tuple{Int, Int}}()  # Dictionnaire pour mémoriser le parent de chaque nœud
    visited = Set{Tuple{Int, Int}}()  # Ensemble pour stocker les nœuds visités
    nodes_visited = 0  # Compteur du nombre de nœuds explorés

    while !isempty(queue)  # Tant que la file n'est pas vide
        courant = popfirst!(queue)  # Récupère et retirer le premier nœud de la file
        nodes_visited += 1  # Incrémente le compteur de nœuds visités
        push!(visited, courant)  # Marque le nœud courant comme visité
        if courant == arrivee  # Si le nœud courant est le point d'arrivée, sortir de la boucle
            break
        end
        for voisin in get_voisins(courant, grille)  # Pour chaque voisin du nœud courant
            if voisin ∉ visited && !(voisin in queue)  # Si le voisin n'a pas encore été visité ni ajouté à la file
                push!(queue, voisin)  # Ajoute le voisin à la file d'attente
                parents[voisin] = courant  # Enregistre le nœud courant comme parent de ce voisin
            end
        end
    end

    chemin = []  # Initialise le tableau qui contiendra le chemin trouvé
    if courant == arrivee || arrivee ∈ keys(parents) || depart == arrivee
        courant = arrivee  # Commence la reconstruction du chemin à partir du point d'arrivée
        push!(chemin, courant)  # Ajoute l'arrivée dans le chemin
        while courant != depart  # Tant que le départ n'est pas atteint
            if haskey(parents, courant)  # Si un parent est enregistré pour le nœud courant
                courant = parents[courant]  # Mettre à jour le nœud courant avec son parent
                push!(chemin, courant)  # Ajoute ce nœud au chemin
            else
                break  # Sort de la boucle en cas d'absence de parent (cas anormal)
            end
        end
        chemin = reverse(chemin)  # Inverse le tableau pour obtenir l'ordre du départ à l'arrivée comme on les a ajouté depuis le point d'arrivée
    else
        println("Aucun chemin trouvé avec BFS.")  # Affiche un message si aucun chemin n'est trouvé
    end

    cout_total = 0  # Initialise le coût total du chemin
    for case in chemin  # Pour chaque case du chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])  # Ajoute le coût de la case au coût total
    end

    # Affiche le chemin, le nombre de nœuds explorés et la distance totale
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")
    
    affichage_console(grille, chemin, depart, arrivee)  # Affiche le chemin coloré sur la console
end

# --------------------------------------------------------------------------------------------------
# Implémentation de l'algorithme de Dijkstra pour la recherche de chemin
function algoDijkstra(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64})
    grille = chargerFichier(nom_fichier)  # charge le terrain depuis le fichier .map
    if !isValidCoordinate(depart, grille)  # Vérifie la validité du point de départ
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)  # Vérifie la validité du point d'arrivée
        error("Le point d'arrivée $arrivee est invalide.")
    end
    # Vérifie que le point de départ n'est pas sur un obstacle
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    # Vérifie que le point d'arrivée n'est pas sur un obstacle
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W'] 
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end
    
    nbr_rows = length(grille)  # Nombre total de lignes de la grille
    nbr_cols = length(grille[1])  # Nombre total de colonnes de la grille
    dist = Dict{Tuple{Int64, Int64}, Float64}()  # Dictionnaire pour stocker la distance minimale à chaque nœud
    prev = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}()  # Dictionnaire pour mémoriser le prédécesseur de chaque nœud
    permanent = Dict{Tuple{Int64, Int64}, Bool}()  # Dictionnaire pour indiquer si la distance d'un nœud est définitivement fixée
    nodes = Tuple{Int64, Int64}[]  # Tableau qui contiendra toutes les coordonnées (nœuds) de la grille
    for i in 1:nbr_rows  # Parcourt chaque ligne
        for j in 1:nbr_cols  # Parcourt chaque colonne
            coordonnees = (i, j)  # Crée le tuple de coordonnées
            dist[coordonnees] = Inf  # Initialise la distance à l'infini
            permanent[coordonnees] = false  # Marque le nœud comme non permanent
            push!(nodes, coordonnees)  # Ajoute le nœud à la liste des nœuds
        end
    end
    dist[depart] = 0.0  # La distance du point de départ à lui-même est 0
    nodes_visited = 0  # Initialise le compteur de nœuds visités

    # Boucle principale de l'algorithme de Dijkstra
    while any(!permanent[node] for node in nodes)  # Tant qu'il existe des nœuds non définitivement fixés
        courant = nothing  # Initialise la variable pour le nœud courant
        current_dist = Inf  # Initialise la distance minimale courante à l'infini
        for node in nodes  # Parcourt tous les nœuds
            if !permanent[node] && dist[node] < current_dist  # Si le nœud n'est pas permanent et sa distance est inférieure
                courant = node  # Sélectionne ce nœud comme nœud courant
                current_dist = dist[node]  # Mettre à jour la distance minimale courante
            end
        end
        if courant === nothing  # Si aucun nœud n'a été trouvé, sortir de la boucle
            break
        end
        permanent[courant] = true  # Marque le nœud courant comme définitivement fixé
        nodes_visited += 1  # Incrémente le compteur de nœuds visités
        if courant == arrivee  # Si le nœud courant est le point d'arrivée, la recherche est terminée
            break
        end
        for voisin in get_voisins(courant, grille)  # Pour chaque voisin du nœud courant
            if !permanent[voisin]  # Si le voisin n'est pas encore définitivement fixé
                # Calcule le coût alternatif pour atteindre le voisin via le nœud courant
                alt = dist[courant] + cout_mouvement(grille[voisin[1]][voisin[2]])
                if alt < dist[voisin]  # Si ce coût est inférieur à la distance actuellement enregistrée pour le voisin
                    dist[voisin] = alt  # Mettre à jour la distance du voisin
                    prev[voisin] = courant  # Enregistre le nœud courant comme prédécesseur du voisin
                end
            end
        end
    end

    chemin = []  # Initialise le tableau qui contiendra le chemin trouvé
    if arrivee == depart
        chemin = [depart]  # Si le départ et l'arrivée sont identiques, le chemin est composé d'un seul point
    elseif haskey(prev, arrivee)
        courant = arrivee  # Commence la reconstruction du chemin à partir de l'arrivée
        push!(chemin, courant)  # Ajoute le point d'arrivée au chemin
        while courant != depart  # Remonte le chemin jusqu'au point de départ
            if haskey(prev, courant)  # Si un prédécesseur existe pour le nœud courant
                courant = prev[courant]  # Mettre à jour le nœud courant avec son prédécesseur
                push!(chemin, courant)  # Ajoute ce nœud au chemin
            else
                break  # Sortir si aucun prédécesseur n'est trouvé
            end
        end
        chemin = reverse(chemin)  # Inverse le chemin pour obtenir l'ordre du départ à l'arrivée
    else
        println("Aucun chemin trouvé avec Dijkstra.")  # Affiche un message si aucun chemin n'a été trouvé
    end

    cout_total = 0.0  # Initialise la variable pour le coût total du chemin
    for case in chemin  # Pour chaque case du chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])  # Ajoute le coût de la case au coût total
    end

    # Affiche le chemin, le nombre de nœuds visités et la distance totale
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")

    affichage_console(grille, chemin, depart, arrivee)  # Affiche le chemin coloré sur la console
end

# --------------------------------------------------------------------------------------------------
# Fonction heuristique utilisée dans l'algorithme Arrivée* (calcul de la distance de Manhattan)
function heuristique(a::Tuple{Int64, Int64}, b::Tuple{Int64, Int64})
    # Retourne la somme des différences absolues des coordonnées (distance de Manhattan)
    return abs(a[1] - b[1]) + abs(a[2] - b[2])
end

# --------------------------------------------------------------------------------------------------
# Implémentation de l'algorithme Arrivée* (A*) pour la recherche de chemin
function algoAstar(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64})
    grille = chargerFichier(nom_fichier)  # Charger le terrain depuis le fichier .map
    if !isValidCoordinate(depart, grille)  # Vérifie la validité du point de départ
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)  # Vérifie la validité du point d'arrivée
        error("Le point d'arrivée $arrivee est invalide.")
    end
    # Vérifie que le point de départ ne se trouve pas sur un obstacle
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    # Vérifie que le point d'arrivée ne se trouve pas sur un obstacle
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W'] 
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end
    
    # Initialisation des dictionnaires pour les scores g et f de chaque nœud
    cout_g = Dict{Tuple{Int64, Int64}, Float64}()  # cout_g : coût pour atteindre le nœud depuis le départ
    cout_f = Dict{Tuple{Int64, Int64}, Float64}()  # cout_f : somme de cout_g et de l'heuristique jusqu'à l'arrivée
    pred = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}()  # Pour retracer le chemin (prédécesseur de chaque nœud)
    nbr_rows = length(grille)  # Nombre de lignes de la grille
    nbr_cols = length(grille[1])  # Nombre de colonnes de la grille
    for i in 1:nbr_rows  # Pour chaque ligne
        for j in 1:nbr_cols  # Pour chaque colonne
            coordonnees = (i, j)  # Créer le tuple de coordonnées
            cout_g[coordonnees] = Inf  # Initialise cout_g à l'infini
            cout_f[coordonnees] = Inf  # Initialise cout_f à l'infini
        end
    end
    cout_g[depart] = 0.0  # Le coût pour atteindre le départ est 0
    cout_f[depart] = heuristique(depart, arrivee)  # cout_f initial du départ est égal à l'heuristique vers l'arrivée
    open_set = Set{Tuple{Int64, Int64}}()  # Ensemble des nœuds à explorer (open set)
    push!(open_set, depart)  # Ajoute le point de départ à l'open set
    nodes_visited = 0  # Initialise le compteur de nœuds visités

    courant = nothing  # Initialise la variable pour le nœud courant
    while !isempty(open_set)  # Tant que l'open set n'est pas vide
        courant = nothing  # Réinitialise le nœud courant
        current_f = Inf  # Initialise la valeur f courante à l'infini
        for node in open_set  # Parcourir tous les nœuds de l'open set
            if cout_f[node] < current_f  # Si le cout_f du nœud est inférieur à la valeur actuelle minimale
                current_f = cout_f[node]  # Mettre à jour la valeur minimale
                courant = node  # Sélectionner ce nœud comme nœud courant
            end
        end
        if courant == arrivee  # Si le nœud courant est le point d'arrivée, la recherche est terminée
            break
        end
        delete!(open_set, courant)  # Retirer le nœud courant de l'open set
        nodes_visited += 1  # Incrémente le compteur de nœuds visités
        for voisin in get_voisins(courant, grille)  # Pour chaque voisin du nœud courant
            # Calcule le coût pour atteindre le voisin via le nœud courant
            tentative_g = cout_g[courant] + cout_mouvement(grille[voisin[1]][voisin[2]])
            if tentative_g < cout_g[voisin]  # Si ce coût est inférieur au coût actuel pour atteindre le voisin
                pred[voisin] = courant  # Enregistre le nœud courant comme prédécesseur du voisin
                cout_g[voisin] = tentative_g  # Mettre à jour cout_g pour le voisin
                # cout_f est la somme de cout_g et de l'heuristique vers l'arrivée
                cout_f[voisin] = tentative_g + heuristique(voisin, arrivee)
                push!(open_set, voisin)  # Ajoute le voisin à l'open set pour exploration ultérieure
            end
        end
    end

    chemin = []  # Initialise le tableau qui contiendra le chemin trouvé
    if courant == arrivee
        current_node = arrivee  # Commencer la reconstruction du chemin à partir de l'arrivée
        push!(chemin, current_node)  # Ajoute l'arrivée au chemin
        while current_node != depart  # Remonter le chemin jusqu'au départ
            if haskey(pred, current_node)  # Si un prédécesseur existe pour le nœud actuel
                current_node = pred[current_node]  # Mettre à jour current_node avec son prédécesseur
                push!(chemin, current_node)  # Ajoute ce nœud au chemin
            else
                break  # Sortir de la boucle si aucun prédécesseur n'est trouvé
            end
        end
        chemin = reverse(chemin)  # Inverser le chemin pour obtenir l'ordre correct (départ -> arrivée)
    else
        println("Aucun chemin trouvé avec Arrivée*.")  # Affiche un message si aucun chemin n'a été trouvé
    end

    cout_total = 0.0  # Initialise le coût total du chemin
    for case in chemin  # Pour chaque case du chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])  # Ajoute le coût de la case au coût total
    end

    # Affiche le chemin trouvé, le nombre de nœuds visités et la distance totale
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")
    
    affichage_console(grille, chemin, depart, arrivee)  # Affiche le chemin coloré sur la console
end

# --------------------------------------------------------------------------------------------------
# Implémentation de l'algorithme glouton pour la recherche de chemin
function algoGlouton(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64})
    grille = chargerFichier(nom_fichier)  # Charge le terrain depuis le fichier .map
    if !isValidCoordinate(depart, grille)  # Vérifie la validité du point de départ
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)  # Vérifie la validité du point d'arrivée
        error("Le point d'arrivée $arrivee est invalide.")
    end
    # Vérifie que le point de départ ne se trouve pas sur un obstacle
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    # Vérifie que le point d'arrivée ne se trouve pas sur un obstacle
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W'] 
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end
    
    visited = Set{Tuple{Int64, Int64}}()  # Initialise un ensemble pour mémoriser les nœuds visités
    chemin = [depart]  # Le chemin commence par le point de départ
    courant = depart  # Défini le nœud courant comme le point de départ
    nodes_visited = 0  # Initialise le compteur de nœuds visités
    while courant != arrivee  # Tant que l'on n'a pas atteint le point d'arrivée
        push!(visited, courant)  # Marque le nœud courant comme visité
        voisins = get_voisins(courant, grille)  # Récupère les voisins du nœud courant
        unvisited = [n for n in voisins if n ∉ visited]  # Sélectionner les voisins qui n'ont pas encore été visités
        if isempty(unvisited)
            println("Aucun chemin trouvé avec l'algorithme glouton.")  # Affiche un message si aucun chemin n'est possible
            return  # Quitter la fonction
        end
        best_voisin = unvisited[1]  # Initialise le meilleur voisin avec le premier de la liste non visité
        best_voisin_h = heuristique(best_voisin, arrivee)  # Calcule l'heuristique pour ce voisin
        for n in unvisited  # Pour chaque voisin non visité
            h = heuristique(n, arrivee)  # Calcule son heuristique
            if h < best_voisin_h  # Si l'heuristique est meilleure (plus petite) que celle du meilleur actuel
                best_voisin = n  # Mettre à jour le meilleur voisin
                best_voisin_h = h  # Mettre à jour la meilleure valeur d'heuristique
            end
        end
        push!(chemin, best_voisin)  # Ajoute le meilleur voisin sélectionné au chemin
        courant = best_voisin  # Mettre à jour le nœud courant pour la prochaine itération
        nodes_visited += 1  # Incrémente le compteur de nœuds visités
    end

    cout_total = 0  # Initialise le coût total du chemin
    for case in chemin  # Pour chaque case du chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])  # Ajoute le coût de la case au coût total
    end

    # Affiche le chemin, le nombre de nœuds visités et la distance totale
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")

    affichage_console(grille, chemin, depart, arrivee)  # Affiche le chemin coloré sur la console
end
