/**
* Name: G05NavigationDansUnPort
* Based on the internal empty template. 
* Author: ADOSSEHOUN K. JOSUE , ALASSANI Abdoul Saib Gaston, SANDANI Moyéme Jammel.
* Tags: 
*/


model G05NavigationDansUnPort

/* Insert your model definition here */

global { 
	//loading des fichiers: shapes et images
	file qgisFile <- file("../includes/shapefile.shp");
	file layerFile <- file("../includes/maree.shp");
	file card <- image_file("../includes/boat.png");
	//file le_sol <- image_file("../includes/sol2.jpg");
	file satelliteDish <- image_file("../includes/parabole.jpg");
	geometry shape <- envelope(qgisFile);
	geometry freeSpace;
	float boatSize <- 2.0;
	point entryPoint <- {800, 150};
	point entryPoint2 <- {500,0};
	point entryPoint3 <- {800, 0};
	point out <- {800, 380};
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
	list<point> allDockingPoint <- [dockingPoint, dockingPoint2, dockingPoint3, dockingPoint4, dockingPoint5, dockingPoint6, dockingPoint7, dockingPoint8, dockingPoint9, dockingPoint10, dockingPoint11, dockingPoint12, dockingPoint13, dockingPoint14, dockingPoint15];
	list<bool> portRegistered <- [true, true, true, false]; // Environ 75% true et 25% false
	list<string> boatCategory <- ["petit", "moyen", "petit", "grand"]; // Environ 50% petits bateaux, 25% petits.B et 25% Grands.B
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
			boatType <- one_of(boatCategory); //On selectionne au hasard une categorie dans la liste
			if (self.boatType = "grand") {
				tonnage <- rnd(30, 40, 2); //La valeur min 50,max 60 et le pas c'est 2
				previousTonnage <- tonnage;
				loadingSpeed <- 3;
				unloadingSpeed <- 4;
				size <- 30;
				color <- rgb("green");
				travelSpeed <- rnd(5.0) + 1.0;
				portRegistrationStatus <- true;
			}

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

// Création de la couche
		create layer from: layerFile {
			freeSpace <- freeSpace - (shape + boatSize);
		}

// Création du centre de controle
		create controlCenter number: 1 {
			location <- {680, 260};
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

		}

	}

}

//Cet agent représente la partie terrestre de notre environnement, c'est un shape file 
species boatShape {
	float height <- 1.0;

	aspect default {
		draw shape color: #grey depth: height;
		//draw le_sol  ;
		//image "../includes/sol2.jpg";
		
		//draw card size: size * 2;
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
		boat but <- first(tmp sort_by (self distance_to each));
		if (tmp != []) {
			ask but {
				unloadingState <- true;
				myself.freeStatus <- false;
				myself.color <- rgb("red");
				tonnage <- tonnage - unloadingSpeed;
				if (tonnage > 0) {
					myself.isDestination <- isDestination;
				}

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
		if (freeStatus = false) {
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
	int tonnage;
	float travelSpeed;
	int loadingSpeed;
	int unloadingSpeed;
	string boatType <- "";
	bool portRegistrationStatus;
	int rayPerception <- 10;
	point isDestination;
	bool walkingStatus <- true;
	bool returnStatus <- false;
	int size;
	bool waitingState <- false;
	rgb color <- rgb("blue");
	bool canReachPort <- true;
	bool unloadingState <- false;
	bool loadingState <- false;
	int previousTonnage;
	int counting <- 300;
	bool checkingState <- false;

	//On lui donne une icone qui contient l'image d'une photo
	aspect icone {
		draw card size: size * 2;
	}

	reflex checkTideStatus
	//A chaque moment qu'il se deplace, il verifie le niveau de la marée, si celui-ci ne lui convient pas, il communique 
	//avec le centre de controle pour qu'on puisse lui envoyé un bateau de secours etant donné qu'il ne peut pas atteindre le port.
	//Cette action ne concerne que les grands bateaux.
	{
		list pocketOf <- list(layer) where (((each distance_to self)) <= 10); //S'il est proche de la dite couche  
		if (pocketOf != []) {
			ask waterLevelSensor {
				if (myself.boatType = "grand" and waterLevelStatus = "basse") {
					if (myself.returnStatus = false) {
						myself.walkingStatus <- false;
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
	reflex stayOnWait when: returnStatus = false {
		list espac <- list(parkingSpace) where (((each distance_to self)) <= 90);
		int spaceNomber <- length(espac);
		parkingSpace esp <- first(espac sort_by (self distance_to each));
		if (espac != []) {
			ask esp {
				if (freeStatus = false) {
					myself.walkingStatus <- false;
					myself.waitingState <- true;
				}

			}

		}

	}

	//Quand l'agent termine sa mission, il quitte le port
	reflex returning {
	// 
		if (returnStatus = true and walkingStatus = true) {
			self.isDestination <- out;
			walkingStatus <- true;
		}

	}
	//Quand l'agent quitte completement le port, on le tue         
	reflex agentKiller { //Si l'agent arrive au point de out, on le tue
		if (self distance_to out = 0) {
			do die;
		}

	}

	reflex unloading {
		if (unloadingState = true and canReachPort = true) { //On se rapproche du port, pour pouvoir decharger la marchandise
			list spaceList <- list(parkingSpace) where (((each distance_to self)) = 0);
			int spaceNomber <- length(spaceList);
			parkingSpace plac <- first(spaceList sort_by (self distance_to each));
			if (spaceList != []) {
				ask plac { //On fait le unloading du bateau
					myself.walkingStatus <- false;
					myself.tonnage <- myself.tonnage - myself.unloadingSpeed;
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
		if (loadingState = true) { //On se rassure que on a bien accoster
			list spaceList <- list(parkingSpace) where (((each distance_to self)) < 5);
			int spaceNomber <- length(spaceList);
			parkingSpace place <- first(spaceList sort_by (self distance_to each));
			if (spaceList != []) {
				ask place { //On comment à charger la marchandise dans le bateau
					myself.tonnage <- myself.tonnage + myself.loadingSpeed;
					if (myself.tonnage >= myself.previousTonnage) //On verifie si le bateau est entièrement chargé
					{
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

	//Cette action est executée quand le bateau recoit l'ordre venant du centre de controle lui indiquant la place d'acostage.     
	reflex moveToAcostage when: (walkingStatus = true) {
		do action: goto target: isDestination speed: travelSpeed;
		if (returnStatus = false) {
			list spaceListe <- list(parkingSpace) where (((each distance_to self)) = 0);
			parkingSpace place <- first(spaceListe sort_by (self distance_to each));
			if (spaceListe != []) { //une fois arrivé, la dite place devient occupée.
				ask place {
					set freeStatus <- false;
					set col <- rgb('red');
					set myself.returnStatus <- true;
					set myself.unloadingState <- true;
				}

			}

		}

	}

	//ce reflex  permet de créer les agents progressivement afin que le programme ne puisse avoir une carence à un moment
	//donné.              
	reflex createAgentsProgressively {
		list largeBoatList <- list(boat) where ((each.boatType = 'grand'));
		int lorgeBoatNomber <- length(largeBoatList);
		list mediumBoatList <- list(boat);
		int mediumBoatList <- length(mediumBoatList);
		if (lorgeBoatNomber = 1) {
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

		if (mediumBoatList < 20) {
			create boat number: 30 {
				location <- one_of(entryPoint, entryPoint2, entryPoint3);
				boatType <- one_of(list('moyen', 'petit'));
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

species controlCenter skills: [] {
	int size_ <- 10;
	rgb color_ <- rgb("yellow");

	aspect parabole {
		draw satelliteDish size: size_ * 5;
	}

	reflex boatLiftingAuthorizations {
	//On communique avec les bateaux par Radio, donc on  a pas besoin d'un rayon de perception.
		list boatList <- list(boat) where ((each.returnStatus = false) and (each.checkingState = false));
		int boatNomberteau <- length(boatList);
		if (boatList != []) {
		//On communique avec chaque bateau pour pouvoir recuperer les informormations 
			loop i from: 0 to: boatNomberteau {
				int j <- rnd(boatNomberteau - 1);
				boat element <- boatList[j];
				ask element {
					checkingState <- true;
					if (portRegistrationStatus = false) // on verifie si le bateau est enregistré
					{
						isDestination <- out; // on lui dit de rentrer
					}
					//S'il est enregistré              
else {
					//on verifie le nombre des places disponibles
						list spaceList <- list(parkingSpace) where ((each.freeStatus = true));
						int spaceNomber <- length(spaceList);
						if (spaceNomber > 0) {
						//On récupère toutes les places disponibles
							list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
							int spaceNombere <- length(freeSpace);
							if (freeSpace != []) {
								loop i from: 0 to: spaceNombere {
									int j <- rnd(spaceNombere - 1);
									parkingSpace element <- freeSpace[j];
									ask element {
									//On cherche l"espace qui correspond à la size du bateau 	
										if (area >= myself.size) {
										//Si on le trouve, directement on l'affecte au bateau
											myself.isDestination <- element.location;
											//Ici on autorise maintenant le bateau à pouvoir accoster
											//Donc il peut  se diriger vers le port etant donné qu'il a déjà
											//une affectation 
										}

									}

								}

							}

						} else {
							set walkingStatus <- false; //On lui dit de patienter car il n'y a pas d'espace
						}

					}

				}

			}

		}

	}

	//Cette action gère tous les bateaux qui sont en attente, donc tous ceux qui n'ont pas pu accoster
	//En leur attribuant une nouvelle affectation        	                       
	reflex coordinateWaitingBoat {
		list boatList <- list(boat) where ((each.waitingState = true));
		int nb_b <- length(boatList);
		if (boatList != []) {
			loop i from: 0 to: nb_b {
				int j <- rnd(nb_b - 1);
				boat element <- boatList[j];
				ask element {
					list freeSpace <- list(parkingSpace) where ((each.freeStatus = true));
					int spaceNombere <- length(freeSpace);
					if (freeSpace != []) {
						loop i from: 0 to: spaceNombere {
							int j <- rnd(spaceNombere - 1);
							parkingSpace element <- freeSpace[j];
							ask element {
								if (area >= myself.size) {
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

	//Cette action affecte les bateaux de secours aux différents bateaux qui n'ont pas pu accéder au port faute de l'etat basse de la
	//marrée	       
	reflex offloaderBoatAffectaion {
		
	//Il communique avec tous les bateaux concernés       	
		list waitingBoatList <- list(boat) where ((each.canReachPort = false) and (each.unloadingState = false));
		int waitingBoatNomber <- length(waitingBoatList);
		if (waitingBoatList != []) {
			loop i from: 0 to: waitingBoatNomber {
				int j <- rnd(waitingBoatNomber - 1);
				boat eleme <- waitingBoatList[j];
				ask eleme {
					list tmp <- list(offloaderBoat) where ((each.freeStatus = true));
					int boatNomber <- length(tmp);
					if (tmp != []) {
						offloaderBoat but <- first(tmp sort_by (self distance_to each));
						ask but {
							isDestination <- eleme.location;
							boatLocation <- eleme.location;
							walkingStatus <- true;
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