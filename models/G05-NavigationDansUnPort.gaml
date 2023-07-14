/**
* Name: G05NavigationDansUnPort
* Based on the internal empty template. 
* Author: ADOSSEHOUN K. JOSUE , ALASSANI Abdoul Saib Gaston, SANDANI Moyéme Jammel.
* Tags: 
*/


model G05NavigationDansUnPort

/* Insert your model definition here */

global { 
	//chargement des fichiers: shapes et images
	file fichier_Qgis <- file("../includes/shapefile.shp");
	file fichier_couche <- file("../includes/maree.shp");
	file la_carte <- image_file("../includes/boat.png");
	//file le_sol <- image_file("../includes/sol2.jpg");
	file thisSatelliteDish <- image_file("../includes/parabole.jpg");
	geometry shape <- envelope(fichier_Qgis);
	geometry espace_libre;

	float boatSize <- 2.0;

	int portCapacity <- 15;
	
	//les endroits où on va placer les agents espace de stationnement
	point dockingPoint <- {180,40};
	point dockingPoint2 <- {170, 80};
	point dockingPoint3 <- {200, 150};
	point dockingPoint4 <- {173, 190};
	point dockingPoint5 <- {200, 230};
	point dockingPoint6 <- {205, 280};
	point dockingPoint7 <- {240, 302};
	point dockingPoint8 <- {280, 320};
	point dockingPoint9 <- {305, 355};
	point dockingPoint10 <- {350, 385};
	point dockingPoint11 <- {410, 390};
	point dockingPoint12 <- {500, 390};
	point dockingPoint13 <- {590, 395};
	point dockingPoint14 <- {680, 395};
	point dockingPoint15 <- {770, 400};
	float opacity;
	
	list<point> emplacement_acostage <- [dockingPoint, dockingPoint2, dockingPoint3, dockingPoint4, dockingPoint5, dockingPoint6, dockingPoint7, dockingPoint8, dockingPoint9, dockingPoint10, dockingPoint11, dockingPoint12, dockingPoint13, dockingPoint14, dockingPoint15];	
  list<bool> enregistrement_port <- [true, true, true, false]; // Environ 75% true et 25% false
	list<string> boatCategory <- ["petit", "moyen", "petit", "grand"]; // Environ 50% petits boatx, 25% petits.B et 25% Grands.B

	string etat <- "basse";

	init {
		espace_libre <- copy(shape);
//		Création de la forme du boat
		create la_forme from: fichier_Qgis {

// Création du capteur
		create capteur_niveau_eau number: 1 {
			espace_libre <- espace_libre - (shape + boatSize);
			etat_niveau_eau <- etat;
		}
// Création de boatx
		create boat number: 10 {
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
				portRegisteredStatus <- true;

			}

			if (self.boatType = "moyen") {
				tonnage <- rnd(20, 30, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 2;
				unloadingSpeed <- 2;
				taille <- 20;
				couleur <- rgb("blue");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegisteredStatus <- one_of(enregistrement_port);

			}

			if (self.boatType = "petit") {
				tonnage <- rnd(10, 20, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 1;
				unloadingSpeed <- 1;
				taille <- 10;
				travelSpeed <- rnd(5.0) + 1.0;
				couleur <- rgb("black");
				portRegisteredStatus <- one_of(enregistrement_port);

			}

		}

// Création de la couche
		create la_couche from: fichier_couche {

			espace_libre <- espace_libre - (shape + boatSize);
		}

// Création du centre de controle
		create controlCenter number: 1 {
			location <- {680, 260};
		}
		//On crée un agent espace de stationnement sur chaque place d'acostage
		loop i from: 0 to: portCapacity - 1 {
			point element <- emplacement_acostage[i];
			location <- element;
			// Point de stationnement
			create parkingSpace number: 1 {
				location <- element;
				area <- one_of(list(30, 30, 10, 20));
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


//Cet agent représente les boatx qui auront comme mission de charger et decharger les grands boat qui ne pourront pas acceder
//au port, cette situation sera possible quand le niveau de la marée sera basse.    
species offloaderBoat skills: [moving] {
	point boatDestination;
	rgb couleur <- rgb("white");
	int taille <- 10;
	bool freeStatus <- true;
	point boatLoc;
	bool patienceStatus <- false;


	aspect default {
		draw square(taille) color: couleur;
	}

	//Cette action sera executée sous l'ordre de l'agent centre de controle, c'est lui qui coordonne tous les trafics.
	reflex RescueLargeBoats {
		list tmp <- list(boat) where ((each.boatType = 'grand') and ((each distance_to self) < 5) and (each.canReachPort = false));
		boat but <- first(tmp sort_by (self distance_to each));
		if (tmp != []) {
			ask but {
				unloadingState <- true;
				myself.freeStatus <- false;

				myself.couleur <- rgb("red");
				tonnage <- tonnage - unloadingSpeed;
				if (tonnage > 0) {
					myself.boatDestination <- boatDestination;
				}

				if (tonnage <= 0) {
					myself.boatDestination <- boatDestination;
					myself.freeStatus <- true;
					myself.couleur <- rgb("white");
					returnState <- true;
					patienceStatus <- true;
					boatDestination <- sortie;
				}

			}

		}

	}

	reflex se_deplacer_vers_son_but {
		if (patienceStatus = true) {
			do action: goto target: boatDestination speed: 10.0;
		}

	}

	reflex retour_au_port {
	//C'est cette action qui va permettre à l'agent de faire le va et vient pendant le dechagement/chargement
	//Donc il se rapproche du boat, il recupere la marchandise, puis il se dirige vers le port où le boat devrait accoster.
		if (freeStatus = false) {
			list tmpt <- list(parkingSpace) where ((each distance_to self) <= 0);
			int nb_ <- length(tmpt);
			if (tmpt != []) {
				boatDestination <- boatLoc;
			}

		}

	}

}

//Cette agent représente le boat 
species boat skills: [moving] {
	int tonnage;
	float travelSpeed;
	int loadingSpeed;
	int unloadingSpeed;
	string boatType <- "";
	bool portRegisteredStatus;
	int rayPerception <- 10;
	point boatDestination;
	bool patienceStatus <- true;
	bool returnState <- false;

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
	//avec le centre de controle pour qu'on puisse lui envoyé un boat de secours etant donné qu'il ne peut pas atteindre le port.
	//Cette action ne concerne que les grands boatx.
	{
		list proche_de <- list(la_couche) where (((each distance_to self)) <= 10); //S'il est proche de la dite couche  
		if (proche_de != []) {
			ask capteur_niveau_eau {
				if (myself.boatType = "grand" and etat_niveau_eau = "basse") {
					if (myself.returnState = false) {
						myself.patienceStatus <- false;

					}

					myself.canReachPort <- false;
				}

			}

		}

	}

	//Cette action sera executée quand l'agent trouve que son but est occupé par un autre boat qui decharge la marchandise,
	//cette situation peut arriver etant donné que la vitesse des boatx est donnée aleatoirement, donc certains seront plus
	//rapides que les autres. Dans ce cas, le boat va communiquer avec le centre de controle pour qu'on lui donne une autre
	//affectation pour pouvoir accoster. Il sera d'abord en attente pendant ce processus.
	reflex rester_en_attente when: returnState = false {
		list espac <- list(parkingSpace) where (((each distance_to self)) <= 90);
		int spaceNbac <- length(espac);
		parkingSpace esp <- first(espac sort_by (self distance_to each));
		if (espac != []) {
			ask esp {
				if (freeStatus = false) {
					myself.patienceStatus <- false;

					myself.waitingState <- true;
				}

			}

		}

	}

	//Quand l'agent termine sa mission, il quitte le port
	reflex retourner {
	// 
		if (returnState = true and patienceStatus = true) {
			self.boatDestination <- sortie;
			patienceStatus <- true;
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
			list listSpaceac <- list(parkingSpace) where (((each distance_to self)) = 0);
			int spaceNbac <- length(listSpaceac);
			parkingSpace plac <- first(listSpaceac sort_by (self distance_to each));
			if (listSpaceac != []) {
				ask plac { //On fait le dechargement du boat
					myself.patienceStatus <- false;

					myself.tonnage <- myself.tonnage - myself.unloadingSpeed;
					if (myself.tonnage <= 0) {
						myself.tonnage <- 0;
						myself.unloadingState <- false;
						myself.patienceStatus <- false;

						myself.loadingState <- true;
					}

				}

			}

		}

	}

	reflex chargement {
		if (loadingState = true) { //On se rassure que on a bien accoster
			list listSpace <- list(parkingSpace) where (((each distance_to self)) < 5);
			int spaceNb <- length(listSpace);
			parkingSpace place <- first(listSpace sort_by (self distance_to each));
			if (listSpace != []) {
				ask place { //On comment à charger la marchandise dans le boat
					myself.tonnage <- myself.tonnage + myself.loadingSpeed;
					if (myself.tonnage >= myself.previousTonnage) //On verifie si le boat est entièrement chargé

					{
						freeStatus <- true;
						ma_couleur <- rgb("white");
						myself.patienceStatus <- true;
						myself.returnState <- true;
						myself.boatDestination <- sortie;

						myself.unloadingState <- false;
					}

				}

			}

		}

	}

	//Cette action est executée quand le boat recoit l'ordre venant du centre de controle lui indiquant la place d'acostage.     
	reflex aller_place_accostage when: (patienceStatus = true) {
		do action: goto target: boatDestination speed: travelSpeed;
		if (returnState = false) {
			list listSpaceace <- list(parkingSpace) where (((each distance_to self)) = 0);
			parkingSpace place <- first(listSpaceace sort_by (self distance_to each));
			if (listSpaceace != []) { //une fois arrivé, la dite place devient occupée.

				ask place {
					set freeStatus <- false;
					set ma_couleur <- rgb('red');
					set myself.returnState <- true;

					set myself.unloadingState <- true;
				}

			}

		}

	}

	//ce reflex  permet de créer les agents progressivement afin que le programme ne puisse avoir une carence à un moment
	//donné.              
	reflex creer_progressivement_les_agents {
		list largeBoatsList <- list(boat) where ((each.boatType = 'grand'));
		int nbLargeBoat <- length(largeBoatsList);
		list listMediumSizeBoat <- list(boat);
		int nbMediumSizedBoat <- length(listMediumSizeBoat);
		if (nbLargeBoat = 1) {
			create boat number: 1 {

				location <- one_of(entree, entree2, entree3);
				boatType <- 'grand';
				tonnage <- rnd(30, 40, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 3;
				unloadingSpeed <- 4;
				taille <- 30;
				couleur <- rgb("green");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegisteredStatus <- true;

			}

		}

		if (nbMediumSizedBoat < 20) {
			create boat number: 30 {

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
					portRegisteredStatus <- one_of(enregistrement_port);

				}

				if (self.boatType = "petit") {
					tonnage <- rnd(10, 20, 2);
					previousTonnage <- tonnage;
					loadingSpeed <- 1;
					unloadingSpeed <- 1;
					taille <- 10;
					travelSpeed <- rnd(5.0) + 1.0;
					couleur <- rgb("black");
					portRegisteredStatus <- one_of(enregistrement_port);

				}

			}

		}

	}

}

//Cet agent représente les places sur lesquelles les boatx doivent s'accoster  
species parkingSpace skills: [] {
	int area;
	rgb ma_couleur <- rgb("khaki");
	int taille;
	bool freeStatus <- true;

	aspect default {
		draw circle(area / 2) color: ma_couleur;
	}

}

species controlCenter skills: [] {
	int size <- 10;
	rgb color <- rgb("yellow");

	aspect satelliteDish {
		draw thisSatelliteDish size: size * 5;
	}

	reflex acostagePermitsToBoats {
	//On communique avec les boatx par Radio, donc on  a pas besoin d'un rayon de perception.
		list boatList <- list(boat) where ((each.returnState = false) and (each.checkingState = false));
		int boatNumber <- length(boatList);
		if (boatList != []) {
		//On communique avec chaque boat pour pouvoir recuperer les informormations 
			loop i from: 0 to: boatNumber {
				int j <- rnd(boatNumber - 1);
				boat element <- boatList[j];
				ask element {
					checkingState <- true;
					if (portRegisteredStatus = false) // on verifie si le boat est enregistré

					{
						boatDestination <- sortie; // on lui dit de rentrer
					}
					//S'il est enregistré              
else {
					//on verifie le nombre des places disponibles
						list listSpace <- list(parkingSpace) where ((each.freeStatus = true));
						int spaceNb <- length(listSpace);
						if (spaceNb > 0) {
						//On récupère toutes les places disponibles
							list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
							int spaceNbace <- length(freeSpace);
							if (freeSpace != []) {
								loop i from: 0 to: spaceNbace {
									int j <- rnd(spaceNbace - 1);
									parkingSpace element <- freeSpace[j];
									ask element {
									//On cherche l"espace qui correspond à la taille du boat 	
										if (area >= myself.taille) {
										//Si on le trouve, directement on l'affecte au boat
											myself.boatDestination <- element.location;
											//Ici on autorise maintenant le boat à pouvoir accoster
											//Donc il peut  se diriger vers le port etant donné qu'il a déjà
											//une affectation 
										}

									}

								}

							}

						} else {
							set patienceStatus <- false; //On lui dit de patienter car il n'y a pas d'espace
						}

					}

				}

			}

		}

	}

	//Cette action gère tous les boatx qui sont en attente, donc tous ceux qui n'ont pas pu accoster
	//En leur attribuant une nouvelle affectation        	                       
	reflex coordinateWaitingBoat {
		list list_bato <- list(boat) where ((each.waitingState = true));

		int nb_b <- length(list_bato);
		if (list_bato != []) {
			loop i from: 0 to: nb_b {
				int j <- rnd(nb_b - 1);
				boat element <- list_bato[j];
				ask element {
					list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
					int spaceNbace <- length(freeSpace);
					if (freeSpace != []) {
						loop i from: 0 to: spaceNbace {
							int j <- rnd(spaceNbace - 1);
							parkingSpace element <- freeSpace[j];
							ask element {
								if (area >= myself.taille) {
									myself.boatDestination <- element.location;
									myself.waitingState <- false;
									myself.patienceStatus <- true;

								}

							}

						}

					}

				}

			}

		}

	}

	//Cette action affecte les boatx de secours aux différents boatx qui n'ont pas pu accéder au port faute de l'etat basse de la
	//marrée	       
	reflex donner_affectation_offloaderBoat {
		
	//Il communique avec tous les boatx concernés       	
		list waitBoatList <- list(boat) where ((each.canReachPort = false) and (each.unloadingState = false));
		int boatNumber_att <- length(waitBoatList);
		if (waitBoatList != []) {
			loop i from: 0 to: boatNumber_att {
				int j <- rnd(boatNumber_att - 1);
				boat eleme <- waitBoatList[j];
				ask eleme {
					list tmp <- list(offloaderBoat) where ((each.freeStatus = true));

					int nb_ba <- length(tmp);
					if (tmp != []) {
						offloaderBoat but <- first(tmp sort_by (self distance_to each));
						ask but {
							boatDestination <- eleme.location;
							boatLoc <- eleme.location;
							patienceStatus <- true;

						}

					}

				}

			}

		}

	}

}

experiment groupe05NavigationDansUnPort type: gui {
	parameter "Changer le niveau de la marrée" category: "Niveau d'eau" var: etat <- "basse" among: ["basse", "haute"];
	float minimum_cycle_duration <- 0.04;
	output {
		display map type: opengl {
		image "../includes/fond_bleu.jpg";
			graphics "layer2" transparency: 10 {
			}

			species controlCenter aspect: satelliteDish;
			species la_couche transparency: opacity;
			
			species boat aspect: icone;
			species parkingSpace;
			species la_forme;
			species offloaderBoat;
			graphics "sortie" refresh: false {
      
			}

		}

	}
}
