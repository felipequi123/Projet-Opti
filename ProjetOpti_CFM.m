clear
%lecture des données 
[nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient] = lireFichier('instanceExemple.dat');
%exemple d'appel à la résolution du modèle
[solution, fval] = optimProd(1,nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient);
[solution, fval] = optimProd(2,nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient);


%plotOptim(nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient)




% Question 2
function T = calculerHorizon(I, F, d, b, M)
    % Étendre jusqu'à la fenêtre maximale de livraison de livraison
    TmaxLivraison = max(b);
    % Calculer le temps minimal requis pour la production
    Tprod = 0;
    for i = 1:I
        Tprod = max(Tprod, sum(d(i, :)) / F(i));
    end
    % Calculer le temps minimal pour gérer toutes les livraisons
    Tentrepot = ceil(sum(sum(d)) / M);
    % Prendre le maximum des trois
    T = max([TmaxLivraison, Tprod, Tentrepot]);
end
%Fin Question 2

%%%% PROGRAMMATION DES MODELES (à compléter)%%%%%%%%%%%%%%%
function [solution, fval] = optimProd(modele, nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient)
    %T=30;
    T=calculerHorizon(nbProduits, capaProd, demande, b,capaCrossdock);
    if modele==1
        cout=optimproblem('ObjectiveSense', 'minimize');
        %CREER LES VARIABLES DE DECISION
        x=optimvar("x",nbProduits, T, 'LowerBound', 0);
        y=optimvar("y",nbProduits, nbClients, T, 'LowerBound', 0);
        s=optimvar("s",nbProduits, T, 'LowerBound', 0);
        %CREER L'OBJECTIF
        coutstockage=0;
         
        for i=1:nbProduits
            for t=1:T
               coutstockage=coutstockage+coutStockUsine(i)*s(i,t);  
            end    
        end
        coutpenalite=0;
        for i=1:nbProduits
            for t=1:T
                for j=1:nbClients
                    coutpenalite=coutpenalite+penalite(j)*max(a(j)-t,0)*y(i,j,t) +penalite(j)*max(t-b(j),0)*y(i,j,t);
                end
            end    
        end
        cout.Objective = coutpenalite+coutstockage; 
        
        %CREER LES CONTRAINTES.
        %Production
        for i=1:nbProduits
           for t=1:T
               cout.Constraints.("production_"+i+"_"+t)=x(i,t)<=capaProd(i);
           end
        end
        %Stockage
        for i=1:nbProduits
           for t=1:T-1
               cout.Constraints.("Stockage_"+i+"_"+t)= s(i,t+1) == s(i,t) + x(i,t+1) - sum(y(i,:,t+1));
           end
        end
        

        %Demande
        for i=1:nbProduits
           for j=1:nbClients
               cout.Constraints.("Demande_"+i+"_"+j)=sum(y(i,j,:))==demande(i,j); %: sont 
           end
        end

         %Capacité Entrepot
        for t=1:T
            cout.Constraints.("Entrepot_"+t)=sum(sum(y(:,:,t)))<=capaCrossdock;
        end
        [solution, fval]=solve(cout,'Solver','linprog');

        fprintf("Q minimal c'est:%d\n",fval)

    elseif modele==2
        cout=optimproblem('ObjectiveSense', 'minimize');
        %CREER LES VARIABLES DE DECISION
        x=optimvar("x",nbProduits, T, 'LowerBound', 0);
        y=optimvar("y",nbProduits, nbClients, T, 'LowerBound', 0);
        s=optimvar("s",nbProduits, T, 'LowerBound', 0);
        CamionUsineEntrepot=optimvar("Camion_UE",nbProduits,T,Type="integer",LowerBound=0,UpperBound=1);
        CamionEntrepotClient=optimvar("Camion_EC",nbClients,T,Type="integer",LowerBound=0,UpperBound=1);
        coutTransport=0;
        coutstockage=0;
        %Cout usine
        for i=1:nbProduits
            for t=1:T
               coutTransport=coutTransport+ coutCamionUsine(i)*CamionUsineEntrepot(i,t);  
            end    
        end

        for j=1:nbClients
            for t=1:T
               coutTransport=coutTransport+coutCamionClient(j)*CamionEntrepotClient(j,t);  
            end    
        end

        for i=1:nbProduits
            for t=1:T
               coutstockage=coutstockage+coutStockUsine(i)*s(i,t);  
            end    
        end
        coutpenalite=0;
        for i=1:nbProduits
            for t=1:T
                for j=1:nbClients
                    coutpenalite=coutpenalite+penalite(j)*max(a(j)-t,0)*y(i,j,t) +penalite(j)*max(t-b(j),0)*y(i,j,t);
                end
            end    
        end
        cout.Objective = coutpenalite+coutstockage+coutTransport; 
        
        %CREER LES CONTRAINTES.

        %Production
        for i=1:nbProduits
           for t=1:T
               cout.Constraints.("production_"+i+"_"+t)=x(i,t)<=capaProd(i);
           end
        end
        %Stockage
        for i=1:nbProduits
           for t=1:T-1
               cout.Constraints.("Stockage_"+i+"_"+t)= s(i,t+1) == s(i,t) + x(i,t+1) - sum(y(i,:,t+1));
           end
        end
        
        %Demande
        for i=1:nbProduits
           for j=1:nbClients
               cout.Constraints.("Demande_"+i+"_"+j)=sum(y(i,j,:))==demande(i,j); %: sont 
           end
        end

         %Capacité Entrepot
        for t=1:T
            cout.Constraints.("Entrepot_"+t)=sum(sum(y(:,:,t)))<=capaCrossdock;
        end
        M=1e6;
         %Contrainte Cammions
        for i=1:nbProduits
     
            for t=1:T

                cout.Constraints.("CamionUsineEntre_"+i+"_"+t)= sum(y(i,:,t))<=CamionUsineEntrepot(i,t)*M; 
            end
        end

        for j=1:nbClients
     
            for t=1:T

                cout.Constraints.("CamionEntrepotClient_"+j+"_"+t)= sum(y(:,j,t))<=CamionEntrepotClient(j,t)*M; 
            end
        end



        options=optimoptions('intlinprog','Display','none');
        [solution, fval]=solve(cout,Options=options);

        fprintf("Q minimal c'est:%f\n",fval)



    elseif modele==3 
         %TODO : compléter avec le code de IP2
        fprintf("Pour l'instant, le modèle IP2 n'est pas codé \n"); % ligne à enlever     
    else 
        fprintf("Le paramètre modele devrait valoir 1, 2 ou, 3 \n ")
    end
end


%%% Question 3
function plotOptim(nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient)
    valeurs_Entrepot=100:20:300;
    valeurs_objectives=zeros(size(valeurs_Entrepot));
    for i= 1:length(valeurs_Entrepot)
        M=valeurs_Entrepot(i);
        [solution,fval]=optimProd(1,nbProduits, nbClients, capaProd, M, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient);
        valeurs_objectives(i)=fval;
    end
    figure(1);
    plot(valeurs_Entrepot, valeurs_objectives, '-o');
    xlabel('Capacité de l''entrepôt (M)');
    ylabel('Valeur de la fonction objectif');
    title('Impact de la capacité de l''entrepôt sur la fonction objectif');
    grid on;
end






%%%%%%%FONCTION DE PARSAGE (ne pas modifier)%%%%%%%%
function [nbProduits, nbClients, capaProd, capaCrossdock, demande, a, b, penalite, coutStockUsine, coutCamionUsine, coutCamionClient]=lireFichier(filename)
% lecture du fichier de données
instanceParameters = fileread(filename);
% suppression des éventuels commentaires
instanceParameters = regexprep(instanceParameters, '/\*.*?\*/', '');
% évaluation des paramètres
eval(instanceParameters);
end


