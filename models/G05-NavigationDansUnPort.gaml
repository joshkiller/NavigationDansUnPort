/**
* Name: G05NavigationDansUnPort
* Based on the internal empty template. 
* Author: hk
* Tags: 
*/


model G05NavigationDansUnPort

/* Insert your model definition here */

global { 
	//chargement des fichiers: shapes et images
	file fichier_Qgis <- file("../includes/shapefile.shp");
	file fichier_couche <- file("../includes/maree.shp");
	file la_carte <- image_file("../includes/bateau_2.png");
	//file le_sol <- image_file("../includes/sol2.jpg");
	file la_parabole <- image_file("../includes/parabole.jpg");
	geometry shape <- envelope(fichier_Qgis);
	geometry espace_libre;
	float boatSize <- 2.0;
	point entree <- {16, 350};
	point entree2 <- {600, 450};
	point entree3 <- {300, 450};
	point sortie <- {0, 800};
	int capacite_port <- 15;
	
	//les endroits où on va placer les agents espace de stationnement
	point test <- {150, 280};
	point test2 <- {280, 280};
	point test3 <- {380, 270};
	point test4 <- {490, 260};
	point test5 <- {600, 275};
	point test6 <- {880, 250};
	point test7 <- {1280, 810};
	point test8 <- {770, 270};
	point test9 <- {980, 250};
	point test10 <- {1130, 350};
	point test11 <- {1235, 510};
	point test12 <- {1260, 600};
	point test13 <- {1200, 390};
	point test14 <- {1250, 730};
	point test15 <- {50, 280};
	float opacity;
	list<point> emplacement_acostage <- [test, test2, test3, test4, test5, test6, test7, test8, test9, test10, test11, test12, test13, test14, test15];
	list<bool> enregistrement_port <- [true, true, true, false]; // Environ 75% true et 25% false
	list<string> boatCategory <- ["petit", "moyen", "petit", "grand"]; // Environ 50% petits bateaux, 25% petits.B et 25% Grands.B
	string etat <- "basse";

	init {
		espace_libre <- copy(shape);
//		Création de la forme du bateau
		create la_forme from: fichier_Qgis {
			espace_libre <- espace_libre - (shape + boatSize);
		}
// Création du capteur
		create capteur_niveau_eau number: 1 {
			espace_libre <- espace_libre - (shape + boatSize);
			etat_niveau_eau <- etat;
		}
// Création de bateaux
		create bateau number: 10 {
			location <- one_of(entree, entree2, entree3);
			boatType <- one_of(boatCategory); //On selectionne au hasard une categorie dans la liste
			if (self.boatType = "grand") {
				tonnage <- rnd(30, 40, 2); //La valeur min 50,max 60 et le pas c'est 2
				previousTonnage <- tonnage;
				loadingSpeed <- 3;
				unloadingSpeed <- 4;
				taille <- 30;
				couleur <- rgb("green");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegistrationStatus <- true;
			}

			if (self.boatType = "moyen") {
				tonnage <- rnd(20, 30, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 2;
				unloadingSpeed <- 2;
				taille <- 20;
				couleur <- rgb("blue");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegistrationStatus <- one_of(enregistrement_port);
			}

			if (self.boatType = "petit") {
				tonnage <- rnd(10, 20, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 1;
				unloadingSpeed <- 1;
				taille <- 10;
				travelSpeed <- rnd(5.0) + 1.0;
				couleur <- rgb("black");
				portRegistrationStatus <- one_of(enregistrement_port);
			}

		}

// Création de la couche
		create la_couche from: fichier_couche {
			espace_libre <- espace_libre - (shape + boatSize);
		}

// Création du centre de controle
		create centre_de_controle number: 1 {
			location <- {680, 260};
		}
		//On crée un agent espace de stationnement sur chaque place d'acostage
		loop i from: 0 to: capacite_port - 1 {
			point element <- emplacement_acostage[i];
			location <- element;
			// Point de stationnement
			create espace_de_stationnement number: 1 {
				location <- element;
				surface <- one_of(list(30, 30, 10, 20));
			}
			// Point de déchargement
			create offloaderBoat number: 3 {
				location <- element;
			}

		}

	}

}

//Cet agent représente la partie terrestre de notre environnement, c'est un shape file 
species la_forme {
	float height <- 1.0;

	aspect default {
		draw shape color: #grey depth: height;
		//draw le_sol  ;
		//image "../includes/sol2.jpg";
		
		//draw la_carte size: taille * 2;
	}

}

//Cette agent représente la couche de l'eau qui peut avoir le niveau haut ou bas  
species la_couche skills: [] {
	float height <- 0.0;

	aspect default {
		draw shape color: #blue depth: height;
	}

	reflex changer_niveau_eau {
		list port_ <- list(capteur_niveau_eau); //Il doit communiquer avec le capteur qui mesure le niveau d'eau
		ask capteur_niveau_eau {
			if (etat_niveau_eau = "basse") {

				opacity <- 0.1;
			} else {

				opacity <- 0.9; // Il devient transparent
			}

		}

	}

}

//cet agent mesure le niveau d'eau (de la marée)
species capteur_niveau_eau {
	float height <- 0.0;
	string etat_niveau_eau; //Il prend une valeur au hasard dans la liste, donc si on souhaite 
	//qu'il prenne un autre élément de la liste, 
} //Il faut recompiler.


//Cet agent représente les bateaux qui auront comme mission de charger et decharger les grands bateau qui ne pourront pas acceder
//au port, cette situation sera possible quand le niveau de la marée sera basse.    
species offloaderBoat skills: [moving] {
	point sa_destination;
	rgb couleur <- rgb("white");
	int taille <- 10;
	bool etat_disponible <- true;
	point boatLoc;
	bool etat_marcher <- false;

	aspect default {
		draw square(taille) color: couleur;
	}

	//Cette action sera executée sous l'ordre de l'agent centre de controle, c'est lui qui coordonne tous les trafics.
	reflex RescueLargeBoats {
		list tmp <- list(bateau) where ((each.boatType = 'grand') and ((each distance_to self) < 5) and (each.canReachPort = false));
		bateau but <- first(tmp sort_by (self distance_to each));
		if (tmp != []) {
			ask but {
				unloadingState <- true;
				myself.etat_disponible <- false;
				myself.couleur <- rgb("red");
				tonnage <- tonnage - unloadingSpeed;
				if (tonnage > 0) {
					myself.sa_destination <- sa_destination;
				}

				if (tonnage <= 0) {
					myself.sa_destination <- sa_destination;
					myself.etat_disponible <- true;
					myself.couleur <- rgb("white");
					etat_retour <- true;
					etat_marcher <- true;
					sa_destination <- sortie;
				}

			}

		}

	}

	reflex se_deplacer_vers_son_but {
		if (etat_marcher = true) {
			do action: goto target: sa_destination speed: 10.0;
		}

	}

	reflex retour_au_port {
	//C'est cette action qui va permettre à l'agent de faire le va et vient pendant le dechagement/chargement
	//Donc il se rapproche du bateau, il recupere la marchandise, puis il se dirige vers le port où le bateau devrait accoster.
		if (etat_disponible = false) {
			list tmpt <- list(espace_de_stationnement) where ((each distance_to self) <= 0);
			int nb_ <- length(tmpt);
			if (tmpt != []) {
				sa_destination <- boatLoc;
			}

		}

	}

}

//Cette agent représente le bateau 
species bateau skills: [moving] {
	int tonnage;
	float travelSpeed;
	int loadingSpeed;
	int unloadingSpeed;
	string boatType <- "";
	bool portRegistrationStatus;
	int rayPerception <- 10;
	point sa_destination;
	bool etat_marcher <- true;
	bool etat_retour <- false;
	int taille;
	bool waitingState <- false;
	rgb couleur <- rgb("blue");
	bool canReachPort <- true;
	bool unloadingState <- false;
	bool loadingState <- false;
	int previousTonnage;
	int comptage <- 300;
	bool checkingState <- false;

	//On lui donne une icone qui contient l'image d'une photo
	aspect icone {
		draw la_carte size: taille * 2;
	}

	reflex verifier_etat_maree
	//A chaque moment qu'il se deplace, il verifie le niveau de la marée, si celui-ci ne lui convient pas, il communique 
	//avec le centre de controle pour qu'on puisse lui envoyé un bateau de secours etant donné qu'il ne peut pas atteindre le port.
	//Cette action ne concerne que les grands bateaux.
	{
		list proche_de <- list(la_couche) where (((each distance_to self)) <= 10); //S'il est proche de la dite couche  
		if (proche_de != []) {
			ask capteur_niveau_eau {
				if (myself.boatType = "grand" and etat_niveau_eau = "basse") {
					if (myself.etat_retour = false) {
						myself.etat_marcher <- false;
					}

					myself.canReachPort <- false;
				}

			}

		}

	}

	//Cette action sera executée quand l'agent trouve que son but est occupé par un autre bateau qui decharge la marchandise,
	//cette situation peut arriver etant donné que la vitesse des bateaux est donnée aleatoirement, donc certains seront plus
	//rapides que les autres. Dans ce cas, le bateau va communiquer avec le centre de controle pour qu'on lui donne une autre
	//affectation pour pouvoir accoster. Il sera d'abord en attente pendant ce processus.
	reflex rester_en_attente when: etat_retour = false {
		list espac <- list(espace_de_stationnement) where (((each distance_to self)) <= 90);
		int nb_espac <- length(espac);
		espace_de_stationnement esp <- first(espac sort_by (self distance_to each));
		if (espac != []) {
			ask esp {
				if (etat_disponible = false) {
					myself.etat_marcher <- false;
					myself.waitingState <- true;
				}

			}

		}

	}

	//Quand l'agent termine sa mission, il quitte le port
	reflex retourner {
	// 
		if (etat_retour = true and etat_marcher = true) {
			self.sa_destination <- sortie;
			etat_marcher <- true;
		}

	}
	//Quand l'agent quitte completement le port, on le tue         
	reflex tuer_agent { //Si l'agent arrive au point de sortie, on le tue
		if (self distance_to sortie = 0) {
			do die;
		}

	}

	reflex dechargement {
		if (unloadingState = true and canReachPort = true) { //On se rapproche du port, pour pouvoir decharger la marchandise
			list list_espac <- list(espace_de_stationnement) where (((each distance_to self)) = 0);
			int nb_espac <- length(list_espac);
			espace_de_stationnement plac <- first(list_espac sort_by (self distance_to each));
			if (list_espac != []) {
				ask plac { //On fait le dechargement du bateau
					myself.etat_marcher <- false;
					myself.tonnage <- myself.tonnage - myself.unloadingSpeed;
					if (myself.tonnage <= 0) {
						myself.tonnage <- 0;
						myself.unloadingState <- false;
						myself.etat_marcher <- false;
						myself.loadingState <- true;
					}

				}

			}

		}

	}

	reflex chargement {
		if (loadingState = true) { //On se rassure que on a bien accoster
			list list_esp <- list(espace_de_stationnement) where (((each distance_to self)) < 5);
			int nb_esp <- length(list_esp);
			espace_de_stationnement place <- first(list_esp sort_by (self distance_to each));
			if (list_esp != []) {
				ask place { //On comment à charger la marchandise dans le bateau
					myself.tonnage <- myself.tonnage + myself.loadingSpeed;
					if (myself.tonnage >= myself.previousTonnage) //On verifie si le bateau est entièrement chargé
					{
						etat_disponible <- true;
						ma_couleur <- rgb("white");
						myself.etat_marcher <- true;
						myself.etat_retour <- true;
						myself.sa_destination <- sortie;
						myself.unloadingState <- false;
					}

				}

			}

		}

	}

	//Cette action est executée quand le bateau recoit l'ordre venant du centre de controle lui indiquant la place d'acostage.     
	reflex aller_place_accostage when: (etat_marcher = true) {
		do action: goto target: sa_destination speed: travelSpeed;
		if (etat_retour = false) {
			list list_espace <- list(espace_de_stationnement) where (((each distance_to self)) = 0);
			espace_de_stationnement place <- first(list_espace sort_by (self distance_to each));
			if (list_espace != []) { //une fois arrivé, la dite place devient occupée.
				ask place {
					set etat_disponible <- false;
					set ma_couleur <- rgb('red');
					set myself.etat_retour <- true;
					set myself.unloadingState <- true;
				}

			}

		}

	}

	//ce reflex  permet de créer les agents progressivement afin que le programme ne puisse avoir une carence à un moment
	//donné.              
	reflex creer_progressivement_les_agents {
		list largeBoatsList <- list(bateau) where ((each.boatType = 'grand'));
		int nbLargeBoat <- length(largeBoatsList);
		list listMediumSizeBoat <- list(bateau);
		int nbMediumSizedBoat <- length(listMediumSizeBoat);
		if (nbLargeBoat = 1) {
			create bateau number: 1 {
				location <- one_of(entree, entree2, entree3);
				boatType <- 'grand';
				tonnage <- rnd(30, 40, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 3;
				unloadingSpeed <- 4;
				taille <- 30;
				couleur <- rgb("green");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegistrationStatus <- true;
			}

		}

		if (nbMediumSizedBoat < 20) {
			create bateau number: 30 {
				location <- one_of(entree, entree2, entree3);
				boatType <- one_of(list('moyen', 'petit'));
				if (self.boatType = "moyen") {
					tonnage <- rnd(20, 30, 2);
					previousTonnage <- tonnage;
					loadingSpeed <- 2;
					unloadingSpeed <- 2;
					taille <- 20;
					couleur <- rgb("blue");
					travelSpeed <- rnd(5.0) + 1.0;
					portRegistrationStatus <- one_of(enregistrement_port);
				}

				if (self.boatType = "petit") {
					tonnage <- rnd(10, 20, 2);
					previousTonnage <- tonnage;
					loadingSpeed <- 1;
					unloadingSpeed <- 1;
					taille <- 10;
					travelSpeed <- rnd(5.0) + 1.0;
					couleur <- rgb("black");
					portRegistrationStatus <- one_of(enregistrement_port);
				}

			}

		}

	}

}

//Cet agent représente les places sur lesquelles les bateaux doivent s'accoster  
species espace_de_stationnement skills: [] {
	int surface;
	rgb ma_couleur <- rgb("khaki");
	int taille;
	bool etat_disponible <- true;

	aspect default {
		draw circle(surface / 2) color: ma_couleur;
	}

}

species centre_de_controle skills: [] {
	int taille_ <- 10;
	rgb couleur_ <- rgb("yellow");

	aspect parabole {
		draw la_parabole size: taille_ * 5;
	}

	reflex acostagePermitsToBoats {
	//On communique avec les bateaux par Radio, donc on  a pas besoin d'un rayon de perception.
		list boatList <- list(bateau) where ((each.etat_retour = false) and (each.checkingState = false));
		int boatNumber <- length(boatList);
		if (boatList != []) {
		//On communique avec chaque bateau pour pouvoir recuperer les informormations 
			loop i from: 0 to: boatNumber {
				int j <- rnd(boatNumber - 1);
				bateau element <- boatList[j];
				ask element {
					checkingState <- true;
					if (portRegistrationStatus = false) // on verifie si le bateau est enregistré
					{
						sa_destination <- sortie; // on lui dit de rentrer
					}
					//S'il est enregistré              
else {
					//on verifie le nombre des places disponibles
						list list_esp <- list(espace_de_stationnement) where ((each.etat_disponible = true));
						int nb_esp <- length(list_esp);
						if (nb_esp > 0) {
						//On récupère toutes les places disponibles
							list espace_dispo <- list(espace_de_stationnement) where ((each.etat_disponible = true));
							int nb_espace <- length(espace_dispo);
							if (espace_dispo != []) {
								loop i from: 0 to: nb_espace {
									int j <- rnd(nb_espace - 1);
									espace_de_stationnement element <- espace_dispo[j];
									ask element {
									//On cherche l"espace qui correspond à la taille du bateau 	
										if (surface >= myself.taille) {
										//Si on le trouve, directement on l'affecte au bateau
											myself.sa_destination <- element.location;
											//Ici on autorise maintenant le bateau à pouvoir accoster
											//Donc il peut  se diriger vers le port etant donné qu'il a déjà
											//une affectation 
										}

									}

								}

							}

						} else {
							set etat_marcher <- false; //On lui dit de patienter car il n'y a pas d'espace
						}

					}

				}

			}

		}

	}

	//Cette action gère tous les bateaux qui sont en attente, donc tous ceux qui n'ont pas pu accoster
	//En leur attribuant une nouvelle affectation        	                       
	reflex coordinateWaitingBoat {
		list list_bato <- list(bateau) where ((each.waitingState = true));
		int nb_b <- length(list_bato);
		if (list_bato != []) {
			loop i from: 0 to: nb_b {
				int j <- rnd(nb_b - 1);
				bateau element <- list_bato[j];
				ask element {
					list espace_dispo <- list(espace_de_stationnement) where ((each.etat_disponible = true));
					int nb_espace <- length(espace_dispo);
					if (espace_dispo != []) {
						loop i from: 0 to: nb_espace {
							int j <- rnd(nb_espace - 1);
							espace_de_stationnement element <- espace_dispo[j];
							ask element {
								if (surface >= myself.taille) {
									myself.sa_destination <- element.location;
									myself.waitingState <- false;
									myself.etat_marcher <- true;
								}

							}

						}

					}

				}

			}

		}

	}

	//Cette action affecte les bateaux de secours aux différents bateaux qui n'ont pas pu accéder au port faute de l'etat basse de la
	//marrée	       
	reflex donner_affectation_offloaderBoat {
		
	//Il communique avec tous les bateaux concernés       	
		list waitBoatList <- list(bateau) where ((each.canReachPort = false) and (each.unloadingState = false));
		int waitBoatNumber <- length(waitBoatList);
		if (waitBoatList != []) {
			loop i from: 0 to: waitBoatNumber {
				int j <- rnd(waitBoatNumber - 1);
				bateau eleme <- waitBoatList[j];
				ask eleme {
					list tmp <- list(offloaderBoat) where ((each.etat_disponible = true));
					int nb_ba <- length(tmp);
					if (tmp != []) {
						offloaderBoat but <- first(tmp sort_by (self distance_to each));
						ask but {
							sa_destination <- eleme.location;
							boatLoc <- eleme.location;
							etat_marcher <- true;
						}

					}

				}

			}

		}

	}

}

experiment Groupe3navigationport type: gui {
	parameter "Changer le niveau de la marrée" category: "Niveau d'eau" var: etat <- "basse" among: ["basse", "haute"];
	float minimum_cycle_duration <- 0.04;
	output {
		display map type: opengl {
		image "../includes/fond_bleu.jpg";
			graphics "layer2" transparency: 10 {
			}

			species centre_de_controle aspect: parabole;
			species la_couche transparency: opacity;
			
			species bateau aspect: icone;
			species espace_de_stationnement;
			species la_forme;
			species offloaderBoat;
			graphics "sortie" refresh: false {
				draw sphere(3) at: entree color: #green;
				draw sphere(3) at: sortie color: #green;
				draw sphere(3) at: test color: #red;
				draw sphere(3) at: test2 color: #red;
				draw sphere(3) at: test3 color: #red;
				draw sphere(3) at: test4 color: #red;
				draw sphere(3) at: test5 color: #red;
				draw sphere(3) at: test6 color: #red;
				draw sphere(3) at: test7 color: #red;
				draw sphere(3) at: test8 color: #red;
				draw sphere(3) at: test9 color: #red;
				draw sphere(3) at: test10 color: #red;
				draw sphere(3) at: test11 color: #red;
				draw sphere(3) at: test12 color: #red;
				draw sphere(3) at: test13 color: #red;
				draw sphere(3) at: test14 color: #red;
				draw sphere(3) at: test15 color: #red;
				draw sphere(3) at: entree2 color: #red;
				draw sphere(3) at: entree3 color: #red;
			}

		}

	}

}
