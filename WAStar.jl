# Programme qui implémente 3 versions de l'algorithme de recherche de chemin A* pondéré 
# Le terrain est composé de cases normales ('.') et d'obstacles ('@','T','S','W').
# Le programme vérifie que les points de départ et d'arrivée ne se trouvent pas sur un obstacle.
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
# Implémentation de l'algorithme Weighted A* pour la recherche de chemin
function algoWAstar(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64}, poids::Float64)
    # Début de chrono
    debut=time()
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
    
    # Initialisation des dictionnaires pour les coûts g et f de chaque nœud
    cout_g = Dict{Tuple{Int64, Int64}, Float64}()  # cout_g : coût pour atteindre le nœud depuis le départ
    cout_f = Dict{Tuple{Int64, Int64}, Float64}()  # cout_f : somme de cout_g et de l'heuristique jusqu'à l'arrivée (pondérée)
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
    cout_f[depart] = poids * heuristique(depart, arrivee)  
    
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
                cout_f[voisin] = tentative_g + poids * heuristique(voisin, arrivee)
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
        println("Aucun chemin trouvé avec Weighted A*.")  # Affiche un message si aucun chemin n'a été trouvé
    end

    cout_total = 0.0  # Initialise le coût total du chemin
    for case in chemin  # Pour chaque case du chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])  # Ajoute le coût de la case au coût total
    end

    # Affiche le chemin trouvé, le nombre de nœuds visités et la distance totale
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")

    #fin du chrono
    fin=time()
    temps_ecoule=fin-debut
    println("Temps écoulé : ", temps_ecoule, " S")
end
# Implémentation de l'algorithme Weighted A* (version f(x) = w*g(x) + (1-w)*h(x))
function algoWAstar_V2(nom_fichier::String, 
                           depart::Tuple{Int64, Int64}, 
                           arrivee::Tuple{Int64, Int64}, 
                           poids::Float64)

    # Début du chronométrage
    debut = time()

    if poids>1 
        println("Pas de chemin valable")
    else
    grille = chargerFichier(nom_fichier)
    end
    # Vérifications de validité du départ et de l'arrivée
    if !isValidCoordinate(depart, grille)
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)
        error("Le point d'arrivée $arrivee est invalide.")
    end
    # Vérifie que départ et arrivée ne sont pas sur un obstacle
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W']
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end

    # Initialisation des dictionnaires pour g et f
    cout_g = Dict{Tuple{Int64, Int64}, Float64}()
    cout_f = Dict{Tuple{Int64, Int64}, Float64}()
    pred   = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}()

    nbr_rows = length(grille)
    nbr_cols = length(grille[1])

    for i in 1:nbr_rows
        for j in 1:nbr_cols
            coord = (i, j)
            cout_g[coord] = Inf
            cout_f[coord] = Inf
        end
    end

    # Le coût pour atteindre le départ est 0
    cout_g[depart] = 0.0

    # ---- Changement : f(x) = w*g(x) + (1 - w)*h(x) ----
    # Sur le noeud de départ, g(depart) = 0 :
    cout_f[depart] = poids * cout_g[depart] + (1 - poids)*heuristique(depart, arrivee)

    open_set = Set{Tuple{Int64, Int64}}()
    push!(open_set, depart)
    nodes_visited = 0

    courant = nothing

    while !isempty(open_set)
        courant = nothing
        current_f = Inf

        # Sélection du nœud à plus faible coût f
        for node in open_set
            if cout_f[node] < current_f
                current_f = cout_f[node]
                courant = node
            end
        end

        # Si on a atteint l'arrivée, on arrête
        if courant == arrivee
            break
        end

        delete!(open_set, courant)
        nodes_visited += 1

        # Parcours des voisins
        for voisin in get_voisins(courant, grille)
            # Calcul du coût g(n) = g(courant) + coût_mouvement
            tentative_g = cout_g[courant] + cout_mouvement(grille[voisin[1]][voisin[2]])

            if tentative_g < cout_g[voisin]
                pred[voisin] = courant
                cout_g[voisin] = tentative_g
                
                # ---- Changement : f(x) = w*g(x) + (1 - w)*h(x) ----
                cout_f[voisin] = poids * cout_g[voisin] + (1 - poids)*heuristique(voisin, arrivee)

                push!(open_set, voisin)
            end
        end
    end

    # Reconstruction du chemin
    chemin = []
    if courant == arrivee
        current_node = arrivee
        push!(chemin, current_node)

        while current_node != depart
            if haskey(pred, current_node)
                current_node = pred[current_node]
                push!(chemin, current_node)
            else
                break
            end
        end
        chemin = reverse(chemin)
    else
        println("Aucun chemin trouvé avec Weighted A*.")
    end

    # Calcul du coût total du chemin (somme de mouvements)
    cout_total = 0.0
    for case in chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])
    end

    # Affichage des résultats
    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")

    # Fin du chronométrage
    fin = time()
    temps_ecoule = fin - debut
    println("Temps écoulé : $temps_ecoule S")
end
#-----------------------------------------------------------------------------------------------------
function algoWAstar_V3(nom_fichier::String, depart::Tuple{Int64, Int64}, arrivee::Tuple{Int64, Int64}, initial_weight::Float64, difference::Float64)
    debut = time()
    grille = chargerFichier(nom_fichier)
    
    # Vérifications sur les points de départ et d'arrivée
    if !isValidCoordinate(depart, grille)
        error("Le point de départ $depart est invalide.")
    end
    if !isValidCoordinate(arrivee, grille)
        error("Le point d'arrivée $arrivee est invalide.")
    end
    if grille[depart[1]][depart[2]] in ['@','T','S','W']
        error("Le point de départ $depart est sur un obstacle.")
    end
    if grille[arrivee[1]][arrivee[2]] in ['@','T','S','W']
        error("Le point d'arrivée $arrivee est sur un obstacle.")
    end
    
    # Initialisation des dictionnaires pour les coûts g et f et du prédécesseur
    cout_g = Dict{Tuple{Int64, Int64}, Float64}()
    cout_f = Dict{Tuple{Int64, Int64}, Float64}()
    pred = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64}}()
    nbr_rows = length(grille)
    nbr_cols = length(grille[1])
    
    for i in 1:nbr_rows
        for j in 1:nbr_cols
            coord = (i, j)
            cout_g[coord] = Inf
            cout_f[coord] = Inf
        end
    end
    
    cout_g[depart] = 0.0
    # On initialise le poids courant avec la valeur initiale
    w_courant = initial_weight
    cout_f[depart] = w_courant * heuristique(depart, arrivee)
    
    open_set = Set{Tuple{Int64, Int64}}()
    push!(open_set, depart)
    nodes_visited = 0

    courant = nothing
    while !isempty(open_set)
        courant = nothing
        current_f = Inf
        for node in open_set
            if cout_f[node] < current_f
                current_f = cout_f[node]
                courant = node
            end
        end
        
        if courant == arrivee
            break
        end
        
        delete!(open_set, courant)
        nodes_visited += 1

        # Récupère le nombre de voisins du nœud courant
        nb_voisins = length(get_voisins(courant, grille))
        
        # Mise à jour dynamique de w selon la densité locale
        if nb_voisins > 5
            # Zone dense : on diminue w vers 1
            w_courant = max(1.0, w_courant - difference)
        else
            # Zone peu dense : on augmente w jusqu'à un maximum (ici 3)
            w_courant = min(3.0, w_courant + difference)
        end

        # Pour chaque voisin, on met à jour les coûts
        for voisin in get_voisins(courant, grille)
            tentative_g = cout_g[courant] + cout_mouvement(grille[voisin[1]][voisin[2]])
            if tentative_g < cout_g[voisin]
                pred[voisin] = courant
                cout_g[voisin] = tentative_g
                # Utilisation de w_current dans le calcul du f-score
                cout_f[voisin] = tentative_g + w_courant * heuristique(voisin, arrivee)
                push!(open_set, voisin)
            end
        end
    end
    
    # Reconstruction du chemin
    chemin = []
    if courant == arrivee
        current_node = arrivee
        push!(chemin, current_node)
        while current_node != depart
            if haskey(pred, current_node)
                current_node = pred[current_node]
                push!(chemin, current_node)
            else
                break
            end
        end
        chemin = reverse(chemin)
    else
        println("Aucun chemin trouvé avec Dynamic Weighted A*.")
    end

    # Calcul du coût total du chemin
    cout_total = 0.0
    for case in chemin
        cout_total += cout_mouvement(grille[case[1]][case[2]])
    end

    println("Path Départ->Arrivée: ", join(string.(chemin), " -> "))
    println("Number of states evaluated: $nodes_visited")
    println("Distance Départ->Arrivée: $cout_total")

    fin = time()
    temps_ecoule = fin - debut
    println("Temps écoulé : ", temps_ecoule, " S")
end