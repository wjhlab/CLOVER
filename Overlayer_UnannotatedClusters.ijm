//Wood Lab, developed by Jessie Kanacharoen
//email any questions to skanach2@jh.edu
//SS - 4/28; edited script to correct size from 1250x1250 to 1000x1000
//JK - 5/20; add dialog box for manual ROI size input, stack in number order, fixed plotting error

// Function to append a value to an array (used for tracking missing files)
function appendToArray(arr, value) {
    newLength = arr.length + 1;
    temp = newArray(newLength);
    for (i = 0; i < arr.length; i++) {
        temp[i] = arr[i];
    }
    temp[newLength - 1] = value;
    return temp;
}

// Function to add text annotation to an image
function annotateImage(overlayName) {
    makeRectangle(10, 10, 400, 50); // Adjust the size of the annotation box
    setColor("White");
    setFont("SansSerif", 24, "Antialiased");
    drawString(overlayName, 10, 45); // Adjust coordinates as needed
}

// Step 1: Choose input and output folders
waitForUser("Select the H&E Source Folder");
sourceDir1 = getDirectory("H&E Source Folder");
waitForUser("Select the IMC Source Folder (ClusterPlot)");
sourceDir2 = getDirectory("IMC Source Folder");
waitForUser("Select the Output Folder");
destinationDir = getDirectory("Output Folder");

// Step 1.1: Define ROI size
Dialog.create("Set ROI Size");
Dialog.addNumber("ROI Width (pixels):", 1000);
Dialog.addNumber("ROI Height (pixels):", 1000);
Dialog.show();
roiWidth = Dialog.getNumber();
roiHeight = Dialog.getNumber();


// Step 2: Get list of TIFF files from Folder 1 (H&E images)
fileList = getFileList(sourceDir1);

// Step 3: Prepare arrays to track errors
missingSamples = newArray();
missingSubfolders = newArray();
missingMarkers = newArray();

// Step 4: Get the first subfolder in sourceDir2 to extract the list of subfolder names
subfolderList = getFileList(sourceDir2);
firstSubfolder = ""; // initialize

for (i = 0; i < subfolderList.length; i++) {
    if (File.isDirectory(sourceDir2 + subfolderList[i])) {
        firstSubfolder = subfolderList[i];
        break;
    }
}

if (firstSubfolder == "") {
    exit("No subfolders found in IMC source folder.");
}

print("Using first subfolder: " + firstSubfolder);

// Step 5: Loop through all H&E images in Folder 1
setBatchMode(true); // can change this to false if you want to see the process live
for (i = 0; i < fileList.length; i++) {
    heFile = fileList[i];

    // Skip non-tiff files
    if (!(endsWith(heFile, ".tif") || endsWith(heFile, ".tiff")))
        continue;

    baseName = substring(heFile, 0, indexOf(heFile, ".tif")); // Extract base name without extension
    hePath = sourceDir1 + heFile;

    // Step 6: Open the H&E image (e.g., 01_C1.tiff)
    open(hePath);
    rename("HE");

    // Step 7: Get the corresponding subfolder for the current H&E image
    imcFolder = sourceDir2 + baseName + "/";
    if (!File.exists(imcFolder)) {
        missingSubfolders = appendToArray(missingSubfolders, baseName);
        close(); // Close HE image if subfolder doesn't exist
        continue;
    }

	// Step 8: Get all marker TIFFs from the subfolder and clean their names
	fileArray = getFileList(imcFolder);
	numberNames = newArray();
	nameMap = newArray(); // Map from index to full name (e.g., "1" => "1.tif")
	
	for (j = 0; j < fileArray.length; j++) {
	    name = fileArray[j];
	    if (endsWith(name, ".tiff") || endsWith(name, ".tif")) {
	        // Strip extension
	        if (endsWith(name, ".tiff")) {
	            numericPart = substring(name, 0, lengthOf(name) - 5);
	        } else {
	            numericPart = substring(name, 0, lengthOf(name) - 4);
	        }
	        
	        // Only accept if it's purely numeric
	        if (matches(numericPart, "^[0-9]+$")) {
	            numberNames = appendToArray(numberNames, parseInt(numericPart));
	            nameMap = appendToArray(nameMap, numericPart);
	        }
	    }
	}
	
	// Simple bubble sort to sort both arrays in parallel based on numeric value
	for (a = 0; a < numberNames.length; a++) {
	    for (b = a + 1; b < numberNames.length; b++) {
	        if (numberNames[a] > numberNames[b]) {
	            // Swap in numberNames
	            temp = numberNames[a];
	            numberNames[a] = numberNames[b];
	            numberNames[b] = temp;
	            
	            // Swap in nameMap
	            tempStr = nameMap[a];
	            nameMap[a] = nameMap[b];
	            nameMap[b] = tempStr;
	        }
	    }
	}
	
	cleanNames = nameMap;  // Now cleanNames holds the base names sorted numerically

    // Step 9: Open all marker images for this H&E
    for (j = 0; j < cleanNames.length; j++) {
        markerPath = imcFolder + cleanNames[j] + ".tiff";  // Assume .tiff extension
        if (!File.exists(markerPath)) {
            markerPath = imcFolder + cleanNames[j] + ".tif";  // Check for .tif if .tiff is not found
        }
        open(markerPath);
    }
	    // Step 9.1: Check that all opened images are matching USER INPUT; if not, skip this sample
    selectWindow("HE");
    width = getWidth();
    height = getHeight();
    if (width != roiWidth || height != roiHeight) {
        print("Size mismatch in HE image: " + baseName);
        missingSamples = appendToArray(missingSamples, baseName);
        run("Close All");
        continue;
    }

    sizeMismatch = false;
    for (j = 0; j < cleanNames.length; j++) {
        markerWindow = cleanNames[j] + ".tiff";
        if (!isOpen(markerWindow)) {
            markerWindow = cleanNames[j] + ".tif";
        }
        if (isOpen(markerWindow)) {
            selectWindow(markerWindow);
            w = getWidth();
            h = getHeight();
            if (w != 1000 || h != 1000) {
                print("Size mismatch in marker image: " + cleanNames[j] + " of sample " + baseName);
                sizeMismatch = true;
                break;
            }
        }
    }

    if (sizeMismatch) {
        missingSamples = appendToArray(missingSamples, baseName);
        run("Close All");
        continue;
    }

	// Step 10: Duplicate the H&E image n+1 times (where n is the number of markers)
	dupHE = newArray("HE");
	for (j = 0; j <= cleanNames.length; j++) { 
	    selectWindow("HE");
	    run("Duplicate...", "title=HE-" + (j+1));
	    dupHE = appendToArray(dupHE, "HE-" + (j+1));
	}


	// Step 14: Delete the original H&E image
		selectWindow("HE");
		close();

	
// Step 15: Create 2‑channel composites (marker + H&E)
for (j = 0; j < cleanNames.length; j++) {
    // Build the window titles

    markerWin = cleanNames[j] + ".tiff";   // e.g. "5-1"
    heWin     = dupHE[j+1];             // matching H&E slice

    // Always put marker in channel 1 and H&E in channel 2
    mergeArgs = 
        "c1=[" + markerWin + "]" +
        " c7=[" + heWin     + "]" +
        " create";

    run("Merge Channels...", mergeArgs);
    selectWindow("Composite");
    rename(cleanNames[j]);
}


    // Step 16: Convert all images to RGB before stacking
    //selectWindow("H&E Only");
    //run("RGB Color");
    //selectWindow("ALL");
    //run("RGB Color");
    for (j = 0; j < cleanNames.length; j++) {
        selectWindow(cleanNames[j]);
        run("RGB Color");
    }

    // Step 17: Create a stack in the correct order:
    // marker composites in order of cleanNames[]
    imageList = newArray(); 
    for (j = 0; j < cleanNames.length; j++) {
        imageList = appendToArray(imageList, cleanNames[j]);
    }

    // Reorder and bring each image to front to preserve correct stacking order
    for (j = 0; j < imageList.length; j++) {
        selectWindow(imageList[j]);
    }

    // Step 18: Stack the images
    run("Images to Stack", "name=" + baseName + "_stack title=[] use");
    run("RGB Color");

// Step 19: Annotate each slice in the stack with drop shadow
for (j = 0; j < imageList.length; j++) {
    Stack.setSlice(j+2);  // 1-based index in ImageJ stacks
    overlayName = imageList[j];
    
    // Concatenate the original H&E file name and the overlay name
    annotationText = baseName + " " + overlayName;
    
    // Define the shadow offset and color
    shadowOffsetX = 3;
    shadowOffsetY = 3;
    shadowColor = "Black";
    
    // Draw the shadow (slightly offset)
    makeRectangle(10 + shadowOffsetX, 10 + shadowOffsetY, 400, 50);
    setColor(shadowColor);
    setFont("SansSerif", 36, "Antialiased");
    drawString(annotationText, 10 + shadowOffsetX, 45 + shadowOffsetY);
    
    // Draw the main text (on top of the shadow)
    makeRectangle(10, 10, 400, 50);
    setColor("White");
    setFont("SansSerif", 36, "Antialiased");
    drawString(annotationText, 10, 45);
}

    // Step 20: Save the stack as a TIFF
    saveAs("Tiff", destinationDir + baseName + "_stack.TIFF");

    // Step 21: Close all open images
    run("Close All");
}

// Final Report
print("\n--- Final Report ---");

function joinArray(arr) {
    result = "";
    for (i = 0; i < arr.length; i++) {
        result += arr[i];
        if (i < arr.length - 1) {
            result += ", ";
        }
    }
    return result;
}

if (missingSamples.length > 0) {
    print("Size mismatch between H&E and IMC ROI: " + joinArray(missingSamples));
}
if (missingSubfolders.length > 0) {
    print("Missing overlay subfolders: " + joinArray(missingSubfolders));
}
if (missingMarkers.length > 0) {
    print("Missing marker files: " + joinArray(missingMarkers));
}

if (missingSamples.length == 0 && missingSubfolders.length == 0 && missingMarkers.length == 0) {
    print("Run complete with no issues!");
}
