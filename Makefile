# Variables
JAVAC = javac
JAR = jar
MAIN_CLASS = uid4nps.userid4nps
SRC_DIR = src/uid4nps
BIN_DIR = bin
JAR_NAME = uid4nps.jar

# Targets
.PHONY: all clean run

all: $(JAR_NAME)

# Compile all .java files to .class files
$(BIN_DIR)/%.class: $(SRC_DIR)/%.java
	mkdir -p $(BIN_DIR)
	$(JAVAC) -d $(BIN_DIR) $(shell find $(SRC_DIR) -name "*.java")

# Collect all .class files
CLASSES = $(shell find $(SRC_DIR) -name "*.java" | sed 's|^$(SRC_DIR)/||;s|.java$$|.class|')

# Create the executable jar
$(JAR_NAME): $(patsubst %,$(BIN_DIR)/%,$(CLASSES))
	$(JAR) cfe $(JAR_NAME) $(MAIN_CLASS) -C $(BIN_DIR) .

# Clean compiled files and the jar
clean:
	rm -rf $(BIN_DIR) $(JAR_NAME)

# Run the jar
run: $(JAR_NAME)
	java -jar $(JAR_NAME)
