/**
* Name: G05NavigationDansUnPort
* Based on the internal empty template. 
* Author: ADOSSEHOUN K. JOSUE , ALASSANI Abdoul Saib Gaston, SANDANI Moyéme Jammel.
* Tags: 
*/
model G05NavigationDansUnPort

/* Insert your model definition here */
global {
// Loading des fichiers: shapes et images
// Chargement du fichier shapefile.shp
file qgisFile <- file("../includes/shapefile.shp");
// Chargement du fichier maree.shp
file layerFile <- file("../includes/maree.shp");
// Chargement de l'image du bateau
file card <- image_file("../includes/boat.png");
// Chargement de l'image de la parabole satellite
file satelliteDish <- image_file("../includes/parabole.jpeg");

// Création de la géométrie shape à partir de l'enveloppe du fichier qgisFile
geometry shape <- envelope(qgisFile);
// Création d'une géométrie vide freeSpace
geometry freeSpace;

// Définition de la taille du bateau
float boatSize <- 2.0;
// Définition des points d'entrée
point entryPoint <- {300, 0};
point entryPoint2 <- {150, 0};
point entryPoint3 <- {240, 20};
// Définition du point de sortie
point out <- {100, 10};
// Capacité du port
int portCapacity <- 15;

// Définition des points d'accostage pour les agents
point dockingPoint <- {95, 40};
point dockingPoint2 <- {455, 80};
point dockingPoint3 <- {105, 150};
point dockingPoint4 <- {570, 190};
point dockingPoint5 <- {570, 230};
point dockingPoint6 <- {110, 250};
point dockingPoint7 <- {115, 302};
point dockingPoint8 <- {700, 350};
point dockingPoint9 <- {300, 375};
point dockingPoint10 <- {350, 405};
point dockingPoint11 <- {410, 390};
point dockingPoint12 <- {500, 390};
point dockingPoint13 <- {590, 395};
point dockingPoint14 <- {680, 395};
point dockingPoint15 <- {770, 400};

// Définition des valeurs d'opacité
float opacity;
// Définition des valeurs de tonnage minimum et maximum
float tonnageMin <- 5;
float tonnageMax <- 60;
// Définition des vitesses de chargement et déchargement pour les bateaux de catégorie "grand"
float loadingSpeedGrand <- 5;
float unloadingSpeedGrand <- 7;
// Définition des vitesses de chargement et déchargement pour les bateaux de catégorie "moyen"
float loadingSpeedMoyen <- 4;
float unloadingSpeedMoyen <- 5;
// Définition des vitesses de chargement et déchargement pour les bateaux de catégorie "petit"
float loadingSpeedPetit <- 2;
float unloadingSpeedPetit <- 2;
// Définition des vitesses de déplacement minimum et maximum
float travelSpeedMin <- 1.0;
float travelSpeedMax <- 6.0;
// Définition des couleurs pour chaque catégorie de bateau
//float colorGrand <- rgb("green");
float colorMoyen <- rgb("blue");
float colorPetit <- rgb("black");
// Définition des statuts d'enregistrement du port
float portRegistrationStatusRegistered <- true;
float portRegistrationStatusNotRegistered <- false;
// Liste des points d'accostage
// Liste des points d'accostage
list<point> allDockingPoint <- [
    dockingPoint, dockingPoint2, dockingPoint3, dockingPoint4, dockingPoint5, 
    dockingPoint6, dockingPoint7, dockingPoint8, dockingPoint9, dockingPoint10, 
    dockingPoint11, dockingPoint12, dockingPoint13, dockingPoint14, dockingPoint15
];

// Liste des statuts d'enregistrement du port
list<bool> portRegistered <- [
    true, true, true, false,true,false,true,true,false
]; // Environ 70% true et 30% false

// Liste des catégories de bateaux
list<string> boatCategory <- [
    "petit", "moyen", "petit", "grand", "moyen"
]; // Environ 40% petits bateaux, 40% bateaux moyen et 20% Grands bateaux

// Statut actuel
string status <- "basse";


	init {
		freeSpace <- copy(shape);
		//		Création de la forme du bateau
		create boatShape from: qgisFile {
			freeSpace <- freeSpace - (shape + boatSize);
		}
		// Création du capteur
		create waterLevelSensor number: 1 {
			freeSpace <- freeSpace - (shape + boatSize);
			waterLevelStatus <- status;
		}
		// Création de bateaux
		create boat number: 10 {
			location <- one_of(entryPoint, entryPoint2, entryPoint3);
			boatType <- one_of(boatCategory); // On sélectionne au hasard une catégorie dans la liste
			if (self.boatType = "grand") {
				tonnage <- rnd(tonnageMin, tonnageMax, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- loadingSpeedGrand;
				unloadingSpeed <- unloadingSpeedGrand;
				size <- 40;
				//color <- colorGrand;
				travelSpeed <- rnd(travelSpeedMin, travelSpeedMax);
				portRegistrationStatus <- portRegistrationStatusRegistered;
			} else if (self.boatType = "moyen") {
				tonnage <- rnd(tonnageMin, tonnageMax, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- loadingSpeedMoyen;
				unloadingSpeed <- unloadingSpeedMoyen;
				size <- 25;
				color <- colorMoyen;
				travelSpeed <- rnd(travelSpeedMin, travelSpeedMax);
				portRegistrationStatus <- one_of([portRegistrationStatusRegistered, portRegistrationStatusNotRegistered]);
			} else if (self.boatType = "petit") {
				tonnage <- rnd(tonnageMin, tonnageMax, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- loadingSpeedPetit;
				unloadingSpeed <- unloadingSpeedPetit;
				size <- 10;
				color <- colorPetit;
				travelSpeed <- rnd(travelSpeedMin, travelSpeedMax);
				portRegistrationStatus <- one_of([portRegistrationStatusRegistered, portRegistrationStatusNotRegistered]);
			} }

			// Création de la couche
		create layer from: layerFile {
			freeSpace <- freeSpace - (shape + boatSize);
		}

		// Création du centre de controle
		create controlCenter number: 1 {
			location <- {95, 1};
		}
		//On crée un agent espace de stationnement sur chaque place d'acostage
		loop i from: 0 to: portCapacity - 1 {
			point element <- allDockingPoint[i];
			location <- element;
			// Point de stationnement
			create parkingSpace number: 1 {
				location <- element;
				area <- one_of(list(30, 30, 10, 20));
			}
			// Point de déloading
			create offloaderBoat number: 3 {
				location <- element;
			}

		} } }

		//Cet agent représente la partie terrestre de notre environnement, c'est un shape file 
species boatShape {
	float height <- 1.0;

	aspect default {
		draw shape color: #grey depth: height;
		
	}

}

//Cette agent représente la couche de l'eau qui peut avoir le niveau haut ou bas  
species layer skills: [] {
	float height <- 0.0;

	aspect default {
		draw shape color: #blue depth: height;
	}

	reflex changeWaterLevel {
		list port_ <- list(waterLevelSensor); //Il doit communiquer avec le capteur qui mesure le niveau d'eau
		ask waterLevelSensor {
			if (waterLevelStatus = "basse") {
				opacity <- 0.1;
			} else {
				opacity <- 0.9; // Il devient transparent
			}

		}

	}

}

//cet agent mesure le niveau d'eau (de la marée)
species waterLevelSensor {
	float height <- 0.0;
	string waterLevelStatus; //Il prend une valeur au hasard dans la liste, donc si on souhaite 
	//qu'il prenne un autre élément de la liste, 
} //Il faut recompiler.


//Cet agent représente les bateaux qui auront comme mission de charger et decharger les grands bateau qui ne pourront pas acceder
//au port, cette situation sera possible quand le niveau de la marée sera basse.    
species offloaderBoat skills: [moving] {
	point isDestination;
	rgb color <- rgb("white");
	int size <- 10;
	bool freeStatus <- true;
	point boatLocation;
	bool walkingStatus <- false;

	aspect default {
		draw square(size) color: color;
	}

	//Cette action sera executée sous l'ordre de l'agent centre de controle, c'est lui qui coordonne tous les trafics.
	reflex RescueLargeBoats {
		list tmp <- list(boat) where ((each.boatType = 'grand') and ((each distance_to self) < 5) and (each.canReachPort = false));
		// Sélectionne le bateau le plus proche parmi les bateaux trouvés
		boat but <- first(tmp sort_by (self distance_to each));

		// Vérifie s'il y a des bateaux à secourir
		if (tmp != []) {
		// Demande au bateau sélectionné d'activer l'état de déchargement
			ask but {
				unloadingState <- true;
				myself.freeStatus <- false;
				myself.color <- rgb("red");
				tonnage <- tonnage - unloadingSpeed;

				// Vérification de marchandise dans le bateau
				if (tonnage > 0) {
					myself.isDestination <- isDestination;
				}

				// Vérifions si le dechargement a pris fin
				if (tonnage <= 0) {
					myself.isDestination <- isDestination;
					myself.freeStatus <- true;
					myself.color <- rgb("white");
					returnStatus <- true;
					walkingStatus <- true;
					isDestination <- out;
				}

			}

		}

	}

	reflex moveToGoal {
		if (walkingStatus = true) {
			do action: goto target: isDestination speed: 10.0;
		}

	}

	reflex returnToPort {
	//C'est cette action qui va permettre à l'agent de faire le va et vient pendant le dechagement/loading
	//Donc il se rapproche du bateau, il recupere la marchandise, puis il se dirige vers le port où le bateau devrait accoster.
		if (!freeStatus) {
			list tmpt <- list(parkingSpace) where ((each distance_to self) <= 0);
			int nb_ <- length(tmpt);
			if (tmpt != []) {
				isDestination <- boatLocation;
			}

		}

	}

}

//Cette agent représente le bateau 
species boat skills: [moving] {
	int tonnage; // Capacité de charge du bateau
	float travelSpeed; // Vitesse de déplacement du bateau
	int loadingSpeed; // Vitesse de chargement du bateau
	int unloadingSpeed; // Vitesse de déchargement du bateau
	string boatType <- ""; // Type de bateau
	bool portRegistrationStatus; // Statut d'enregistrement au port
	int rayPerception <- 10; // Rayon de perception du bateau
	point isDestination; // Destination du bateau
	bool walkingStatus <- true; // Statut de déplacement du bateau
	bool returnStatus <- false; // Statut de retour du bateau
	int size; // Taille du bateau
	bool waitingState <- false; // Statut d'attente du bateau
	rgb color <- rgb("blue"); // Couleur du bateau
	bool canReachPort <- true; // Possibilité d'atteindre le port
	bool unloadingState <- false; // Statut de déchargement du bateau
	bool loadingState <- false; // Statut de chargement du bateau
	int previousTonnage; // Capacité de charge précédente du bateau
	int counting <- 300; // Compteur
	bool checkingState <- false; // Statut de vérification

	// Aspect "icone" avec l'image d'une photo représentant le bateau
	aspect icone {
		draw card size: size * 2;
	}

	reflex checkTideStatus
	// Vérifie le niveau de la marée pour les grands bateaux à proximité
	{
	// Recherche des couches d'eau à proximité du bateau
		list pocketOf <- list(layer) where (((each distance_to self)) <= 10);

		// Vérifie s'il y a des couches d'eau à proximité
		if (pocketOf != []) {
		// Demande au capteur de niveau d'eau
			ask waterLevelSensor {
			// Vérifie si le bateau est de type "grand" et si le niveau d'eau est bas
				if (myself.boatType = "grand" and waterLevelStatus = "basse") {
					if (myself.returnStatus = false) {
						myself.walkingStatus <- false;
					}

					myself.canReachPort <- false;
				}

			}

		}

	}

	reflex stayOnWait when: returnStatus = false {
	// Recherche des places de parking à proximité
		list espac <- list(parkingSpace) where (((each distance_to self)) <= 90);
		int spaceNomber <- length(espac);
		parkingSpace esp <- first(espac sort_by (self distance_to each));

		// Vérifie s'il y a des places de parking disponibles à proximité
		if (espac != []) {
		// Demande à la place de parking
			ask esp {
			// Vérifie si la place est occupée
				if (freeStatus = false) {
					myself.walkingStatus <- false;
					myself.waitingState <- true;
				}

			}

		}

	}

	reflex returning {
	// Retourne à la sortie du port si le statut de retour est vrai et le statut de déplacement est vrai
		if (returnStatus = true and walkingStatus = true) {
			self.isDestination <- out;
			walkingStatus <- true;
		}

	}

	reflex agentKiller {
	// Tue le bateau s'il atteint le point de sortie "out"
		if (self distance_to out = 0) {
			do die;
		}

	}

	reflex unloading {
	// Déchargement du bateau si le statut de déchargement est vrai et le bateau peut atteindre le port
		if (unloadingState = true and canReachPort = true) {
		// Recherche des places de parking à proximité
			list spaceList <- list(parkingSpace) where (((each distance_to self)) = 0);
			int spaceNomber <- length(spaceList);
			parkingSpace plac <- first(spaceList sort_by (self distance_to each));

			// Vérifie s'il y a des places de parking disponibles à proximité
			if (spaceList != []) {
			// Demande à la place de parking
				ask plac {
				// Active le statut de déchargement du bateau
					myself.walkingStatus <- false;
					myself.tonnage <- myself.tonnage - myself.unloadingSpeed;

					// Vérifie si le tonnage restant est inférieur ou égal à 0
					if (myself.tonnage <= 0) {
						myself.tonnage <- 0;
						myself.unloadingState <- false;
						myself.walkingStatus <- false;
						myself.loadingState <- true;
					}

				}

			}

		}

	}

	reflex loading {
	// Chargement du bateau si le statut de chargement est vrai
		if (loadingState = true) {
		// Recherche des places de parking à proximité
			list spaceList <- list(parkingSpace) where (((each distance_to self)) < 5);
			int spaceNomber <- length(spaceList);
			parkingSpace place <- first(spaceList sort_by (self distance_to each));

			// Vérifie s'il y a des places de parking disponibles à proximité
			if (spaceList != []) {
			// Demande à la place de parking
				ask place {
				// Charge la marchandise dans le bateau
					myself.tonnage <- myself.tonnage + myself.loadingSpeed;

					// Vérifie si le bateau est entièrement chargé
					if (myself.tonnage >= myself.previousTonnage) {
						freeStatus <- true;
						col <- rgb("white");
						myself.walkingStatus <- true;
						myself.returnStatus <- true;
						myself.isDestination <- out;
						myself.unloadingState <- false;
					}

				}

			}

		}

	}

	reflex moveToAcostage when: (walkingStatus = true) {
	// Déplacement vers la place d'accostage
		do action: goto target: isDestination speed: travelSpeed;

		// Vérifie si le statut de retour est faux
		if (returnStatus = false) {
		// Recherche des places de parking à proximité
			list spaceListe <- list(parkingSpace) where (((each distance_to self)) = 0);
			parkingSpace place <- first(spaceListe sort_by (self distance_to each));

			// Vérifie s'il y a des places de parking disponibles à proximité
			if (spaceListe != []) {
			// Demande à la place de parking
				ask place {
				// Occupation de la place de parking
					set freeStatus <- false;
					set col <- rgb('red');
					set myself.returnStatus <- true;
					set myself.unloadingState <- true;
				}

			}

		}

	}

	reflex createAgentsProgressively {
	// Recherche des bateaux de type "grand"
		list largeBoatList <- list(boat) where ((each.boatType = 'grand'));
		int lorgeBoatNomber <- length(largeBoatList);

		// Vérifie s'il n'y a qu'un seul bateau de type "grand"
		if (lorgeBoatNomber = 1) {
		// Crée un nouveau bateau de type "grand"
			create boat number: 1 {
				location <- one_of(entryPoint, entryPoint2, entryPoint3);
				boatType <- 'grand';
				tonnage <- rnd(30, 40, 2);
				previousTonnage <- tonnage;
				loadingSpeed <- 3;
				unloadingSpeed <- 4;
				size <- 30;
				color <- rgb("green");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegistrationStatus <- true;
			}

		}

		// Recherche des bateaux de type "moyen"
		list mediumBoatList <- list(boat);
		int mediumBoatList <- length(mediumBoatList);

		// Vérifie s'il y a moins de 20 bateaux en tout
		if (mediumBoatList < 20) {
		// Crée de nouveaux bateaux de type "moyen" et "petit"
			create boat number: 30 {
				location <- one_of(entryPoint, entryPoint2, entryPoint3);
				boatType <- one_of(list('moyen', 'petit'));

				// Configuration des attributs en fonction du type de bateau
				if (self.boatType = "moyen") {
					tonnage <- rnd(20, 30, 2);
					previousTonnage <- tonnage;
					loadingSpeed <- 2;
					unloadingSpeed <- 2;
					size <- 20;
					color <- rgb("blue");
					travelSpeed <- rnd(5.0) + 1.0;
					portRegistrationStatus <- one_of(portRegistered);
				}

				if (self.boatType = "petit") {
					tonnage <- rnd(10, 20, 2);
					previousTonnage <- tonnage;
					loadingSpeed <- 1;
					unloadingSpeed <- 1;
					size <- 10;
					travelSpeed <- rnd(5.0) + 1.0;
					color <- rgb("black");
					portRegistrationStatus <- one_of(portRegistered);
				}

			}

		}

	}

}

//Cet agent représente les places sur lesquelles les bateaux doivent s'accoster  
species parkingSpace skills: [] {
	int area;
	rgb col <- rgb("khaki");
	int size;
	bool freeStatus <- true;

	aspect default {
		draw circle(area / 2) color: col;
	}

}

// Espèce "ControlCenter" avec ses attributs et compétences
species controlCenter skills: [] {
	int size_ <- 10; // Taille du centre de contrôle (personnalisé)
	rgb color_ <- rgb("yellow"); // Couleur du centre de contrôle (personnalisé)

	// Aspect "parabole" avec une antenne parabolique représentant le centre de contrôle
	aspect parabole {
		draw satelliteDish size: size_ * 5;
	}

	
	// Reflexe pour affecter des bateaux de secours aux bateaux ne pouvant pas accoster
	reflex offloaderBoatAffectaion {
	// Recherche des bateaux qui ne peuvent pas accéder au port faute de marée basse et qui ne déchargent pas
		list waitingBoatList <- list(boat) where ((each.canReachPort = false) and (each.unloadingState = false));
		int waitingBoatNomber <- length(waitingBoatList);

		// Vérifie s'il y a des bateaux à affecter
		if (waitingBoatList != []) {
		// Traite chaque bateau concerné
			loop i from: 0 to: waitingBoatNomber {
				int j <- rnd(waitingBoatNomber - 1);
				boat eleme <- waitingBoatList[j];
				ask eleme {
				// Recherche des bateaux déchargeurs disponibles
					list tmp <- list(offloaderBoat) where ((each.freeStatus = true));
					int boatNomber <- length(tmp);

					// Vérifie s'il y a des bateaux déchargeurs disponibles
					if (tmp != []) {
						offloaderBoat but <- first(tmp sort_by (self distance_to each));
						ask but {
						// Affecte la position du bateau en attente au bateau déchargeur
							isDestination <- eleme.location;
							boatLocation <- eleme.location;
							walkingStatus <- true;
						}

					}

				}

			}

		}

	}
	// Reflexe pour coordonner les bateaux en attente
	reflex coordinateWaitingBoat {
	// Recherche des bateaux en attente
		list boatList <- list(boat) where ((each.waitingState = true));
		int nb_b <- length(boatList);

		// Vérifie s'il y a des bateaux en attente à traiter
		if (boatList != []) {
		// Traite chaque bateau en attente
			loop i from: 0 to: nb_b {
				int j <- rnd(nb_b - 1);
				boat element <- boatList[j];
				ask element {
				// Recherche des places de parking disponibles
					list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
					int spaceNombere <- length(freeSpace);

					// Vérifie s'il y a des places de parking disponibles
					if (freeSpace != []) {
						loop i from: 0 to: spaceNombere {
							int j <- rnd(spaceNombere - 1);
							parkingSpace element <- freeSpace[j];
							ask element {
							// Vérifie si la taille de la place correspond à la taille du bateau
								if (area >= myself.size) {
								// Affecte la place de parking au bateau
									myself.isDestination <- element.location;
									myself.waitingState <- false;
									myself.walkingStatus <- true;
								}

							}

						}

					}

				}

			}

		}

	}

	
	
	// Reflexe pour autoriser l'accostage des bateaux
	reflex boatLiftingAuthorizations {
	// Recherche des bateaux qui attendent une autorisation d'accostage
		list boatList <- list(boat) where ((each.returnStatus = false) and (each.checkingState = false));
		int boatNomberteau <- length(boatList);

		// Vérifie s'il y a des bateaux à traiter
		if (boatList != []) {
		// Communique avec chaque bateau pour récupérer les informations
			loop i from: 0 to: boatNomberteau {
				int j <- rnd(boatNomberteau - 1);
				boat element <- boatList[j];
				ask element {
					checkingState <- true;

					// Vérifie si le bateau est enregistré au port
					if (portRegistrationStatus = false) {
						isDestination <- out; // Demande au bateau de rentrer
					} else {
					// Vérifie s'il y a des places de parking disponibles
						list spaceList <- list(parkingSpace) where ((each.freeStatus = true));
						int spaceNomber <- length(spaceList);

						// Vérifie s'il y a des places de parking disponibles
						if (spaceNomber > 0) {
						// Sélectionne aléatoirement une place de parking parmi celles disponibles
							list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
							int spaceNombere <- length(freeSpace);
							if (freeSpace != []) {
								loop i from: 0 to: spaceNombere {
									int j <- rnd(spaceNombere - 1);
									parkingSpace element <- freeSpace[j];
									ask element {
									// Vérifie si la taille de la place correspond à la taille du bateau
										if (area >= myself.size) {
										// Affecte la place de parking au bateau
											myself.isDestination <- element.location;
											// Autorise le bateau à accoster en lui donnant une affectation
										}

									}

								}

							}

						} else {
							set walkingStatus <- false; // Demande au bateau de patienter car il n'y a pas d'espace
						}

					}

				}

			}

		}

	}
	

}



experiment groupe05NavigationDansUnPort type: gui {
	parameter "Changer le niveau de la marrée" category: "Niveau d'eau" var: status <- "basse" among: ["basse", "haute"];
	float cycleMinDuration <- 0.04;
	output {
		display map type: opengl {
			image "../includes/fond_bleu.jpg";
			graphics "layer2" transparency: 10 {
			}

			species controlCenter aspect: parabole;
			species layer transparency: opacity;
			species boat aspect: icone;
			species parkingSpace;
			species boatShape;
			species offloaderBoat;
			graphics "out" refresh: false {
			}

		}

	}

}
