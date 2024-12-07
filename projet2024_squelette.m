clear
% Lecture des données
[nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient] = lireFichier('instanceExemple.dat');

% Exemple d'appel à la résolution du modèle
[solution, fval] = optimProd(1, nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient);

%%%% PROGRAMMATION DES MODÈLES (à compléter)%%%%%%%%%%%%%%%
function [solution, fval] = optimProd(modele, nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, ~, ~)
    if modele == 1
        % -------------------------------
        % Paramètres généraux
        % -------------------------------
        T = 30; % Horizon de temps
        n_x = nbProduits * T; % x_it (Production)
        n_s = nbProduits * T; % s_it (Stockage)
        n_y = nbProduits * nbClients * T; % y_ijt (Quantités livrées aux clients)
        nVars = n_x + n_s + n_y; % Nombre total de variables

        % -------------------------------
        % 2. Fonction objectif
        % -------------------------------
        f = zeros(nVars, 1);
        % Coûts de stockage (s_it)
        for i = 1:nbProduits
            for t = 1:T
                f(n_x + (i - 1) * T + t) = coutStockUsine(i); % Coût de s_it
            end
        end
        % Pénalités pour livraisons hors intervalle (y_ijt)
        for i = 1:nbProduits
            for j = 1:nbClients
                for t = 1:T
                    if t < a(j) || t > b(j) % Hors de l'intervalle autorisé
                        f(n_x + n_s + ((i - 1) * nbClients + (j - 1)) * T + t) = penalite(j);
                    end
                end
            end
        end

        % -------------------------------
        % 3. Contraintes
        % -------------------------------
        A = []; b = []; % Matrice des contraintes et vecteur des bornes

        % (a) Contraintes de capacité de production
        for i = 1:nbProduits
            for t = 1:T
                A_prod = zeros(1, nVars);
                A_prod((i - 1) * T + t) = 1; % x_it
                A = [A; A_prod];
                b = [b; capaProd(i)];
            end
        end

        % (b) Contraintes de stockage
        for i = 1:nbProduits
            for t = 1:T
                A_inv = zeros(1, nVars);
                if t > 1
                    A_inv(n_x + (i - 1) * T + (t - 1)) = 1; % Stock précédent (s_it-1)
                end
                A_inv((i - 1) * T + t) = -1; % Production actuelle (x_it)
                A_inv(n_x + (i - 1) * T + t) = -1; % Stock actuel (s_it)
                for j = 1:nbClients
                    A_inv(n_x + n_s + ((i - 1) * nbClients + (j - 1)) * T + t) = 1; % Livraisons (y_ijt)
                end
                A = [A; A_inv];
                b = [b; 0];
            end
        end

        % (c) Contraintes de capacité du crossdock
        for t = 1:T
            A_crossdock = zeros(1, nVars);
            for i = 1:nbProduits
                for j = 1:nbClients
                    A_crossdock(n_x + n_s + ((i - 1) * nbClients + (j - 1)) * T + t) = 1; % y_ijt
                end
            end
            A = [A; A_crossdock];
            b = [b; capaCrossdock];
        end

        % (d) Contraintes de demande des clients
        for i = 1:nbProduits
            for j = 1:nbClients
                A_demande = zeros(1, nVars);
                for t = 1:T
                    A_demande(n_x + n_s + ((i - 1) * nbClients + (j - 1)) * T + t) = 1; % y_ijt
                end
                A = [A; A_demande];
                b = [b; demande(i, j)];
            end
        end

        % -------------------------------
        % 4. Contraintes de non-négativité
        % -------------------------------
        lb = zeros(nVars, 1); % Toutes les variables doivent être >= 0

        % -------------------------------
        % 5. Résolution du problème linéaire
        % -------------------------------
        options = optimoptions('linprog', 'Display', 'off');
        [solution, fval, exitflag] = linprog(f, A, b, [], [], lb, [], options);

        % Vérification de l'état de la solution
        if exitflag == 1
            % Affichage de la solution et de la valeur de la fonction objectif
            disp('Solution optimale :');
            disp(solution);
            disp('Valeur de la fonction objectif :');
            disp(fval);
        else
            disp('La solution n\');
        end

    elseif modele == 2
        % Code pour le modèle IP1
        fprintf("Le modèle IP1 n'est pas encore implémenté.\n");

    elseif modele == 3
        % Code pour le modèle IP2
        fprintf("Le modèle IP2 n'est pas encore implémenté.\n");

    else
        fprintf("Le paramètre modele doit être 1, 2 ou 3.\n");
    end
end


%%% À compléter
function plotOptim(nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient)
    % TODO : À compléter
    fprintf("Pour l'instant, la fonction n'est pas codée.\n"); % Ligne à supprimer      
end

%%%%%%% FONCTION DE PARSAGE (ne pas modifier)%%%%%%%%
function [nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient] = lireFichier(filename)
    % Lecture du fichier de données
    instanceParameters = fileread(filename);
    % Suppression des éventuels commentaires
    instanceParameters = regexprep(instanceParameters, '/\*.*?\*/', '');
    % Évaluation des paramètres
    eval(instanceParameters);
end
