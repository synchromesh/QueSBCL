/* plugin_jni.cpp 11 Mar 25 JDP QueSBCL */

//#include <android/log.h>
#include <jni.h>
#include <pthread.h>
#include <cstdio>
#include <unistd.h>

#include <godot_cpp/variant/utility_functions.hpp>

#include "utils.h"

//#define TAG "QueSBCL/C"
//#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
//#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)
//#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define GLOG(...) godot::UtilityFunctions::print(__VA_ARGS__)

#undef JNI_PACKAGE_NAME
#define JNI_PACKAGE_NAME net_ngake_quesbcl

#undef JNI_CLASS_NAME
#define JNI_CLASS_NAME QueSBCLPlugin

static int redirect_pipe[2];

void *redirect_worker(void *) {
    char buf[1024];
    ssize_t bytes_read;

    GLOG("redirect_worker(): Thread started.");
    while ((bytes_read = read(redirect_pipe[0], buf, sizeof(buf) - 1)) > 0) {
        if (buf[bytes_read - 1] == '\n') --bytes_read;
        buf[bytes_read] = '\0';
    }
    GLOG("redirect_worker(): Thread finished.");

    return nullptr;
}

int redirect_output() {
    // Change stream buffering settings.
    setvbuf(stdout, nullptr, _IOLBF, 0); // Line-buffered
    setvbuf(stderr, nullptr, _IONBF, 0); // Unbuffered
    // Create new pipe for output redirection.
    pipe(redirect_pipe);
    // Redirect stdout & stderr to the pipe input.
    dup2(redirect_pipe[1], 1);
    dup2(redirect_pipe[1], 2);

    pthread_t redirect_thread;
    const int result=pthread_create(&redirect_thread, nullptr, redirect_worker, nullptr);

    if (result == 0) {
       pthread_detach(redirect_thread);
    }
    else {
        GLOG("redirect_output(): pthread_create() failed with code ", result, ", errno = ", errno, " '", strerror(errno), "'");
    }

    return result;
}

extern "C" {
/* SBCL interface. */
extern int initialize_lisp(int argc, const char *argv[], char *envp[]);

/* SBCL FFI alien-callables. */
__attribute__((visibility("default"))) char *(*hello)();

/* Zstandard interface. Ref: https://raw.githack.com/facebook/zstd/release/doc/zstd_manual.html */
extern const char* ZSTD_versionString(void);

JNIEXPORT jint JNICALL JNI_METHOD(initialiseLisp)(JNIEnv *env, jobject, jstring corePath) {
    char *core_filename = strdup(env->GetStringUTFChars(corePath, nullptr));

    GLOG("initialiseLisp(): Zstd version ", ZSTD_versionString(), ", output redirection result ", redirect_output());
    GLOG("initialiseLisp(): Initialising SBCL with core path '", core_filename, "'...");

    //const char *args[] = { "", "--core", "libcore.so", "--disable-ldb", "--disable-debugger" };
    const char *args[] = {"", "--dynamic-space-size", "8192",
                          "--core", core_filename,
                          "--noinform", "--no-userinit",
                          "--disable-ldb", "--disable-debugger" };
    const int result = initialize_lisp(sizeof(args)/sizeof(args[0]), args, nullptr);

    GLOG("initialiseLisp(): Result = ", result);

    return result;
}

JNIEXPORT void JNICALL JNI_METHOD(helloWorld)(JNIEnv *, jobject) {
  godot::UtilityFunctions::print("Hello QueSBCL World from plugin_jni.cpp!");
}

JNIEXPORT jstring JNICALL JNI_METHOD(helloLisp)(JNIEnv *env, jobject) {
    GLOG("helloLisp(): Calling Lisp alien-callable 'hello'...");

    const char *result=hello();

    GLOG("helloLisp(): Result = ", result);

    return env->NewStringUTF(result);
}
}

/*** End of plugin_jni.cpp ***/
