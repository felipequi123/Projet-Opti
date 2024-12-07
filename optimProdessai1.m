function [solution, fval] = optimProd(modele, nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient)

    if modele == 1
        % Initialisation des variables
        T = size(demande, 3); % Nombre de jours
        nbVars = nbProduits * nbClients * T; % Variables pour x_{ijk}
        
        % Fonction objective
        h = 1; % Coût de stockage (à ajuster selon vos données)
        f = []; % TODO : Compléter avec les coûts de production, stockage, transport
        
        % Contraintes
        A = [];
        b = [];
        
        % Contrainte 1 : Capacité de production
        for i = 1:nbProduits
            for k = 1:T
                row = zeros(1, nbVars);
                for j = 1:nbClients
                    index = sub2ind([nbProduits, nbClients, T], i, j, k);
                    row(index) = 1;
                end
                A = [A; row];
                b = [b; capaProd(i)];
            end
        end
        
        % Contrainte 2 : Capacité d'entrepôt
        for k = 1:T
            row = zeros(1, nbVars);
            for i = 1:nbProduits
                for j = 1:nbClients
                    index = sub2ind([nbProduits, nbClients, T], i, j, k);
                    row(index) = 1;
                end
            end
            A = [A; row];
            b = [b; capaCrossdock];
        end

        % Contraintes de non-négativité
        lb = zeros(nbVars, 1); % bornes inférieures (>= 0)
        ub = inf(nbVars, 1); % bornes supérieures (illimitées)

        % Résolution
        options = optimoptions('linprog', 'Display', 'iter');
        [solution, fval] = linprog(f, A, b, [], [], lb, ub, options);
    else
        fprintf("Modèle non pris en charge. Choisissez 1 pour PL.\n");
        solution = [];
        fval = [];
    end
end
