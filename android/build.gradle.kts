allprojects {
    repositories {
       maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        maven(url = "https://repo.huaweicloud.com/repository/maven/")
        maven(url = "https://mirrors.pku.edu.cn/maven/gradle-plugins/")
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
