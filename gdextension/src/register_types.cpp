#include "register_types.h"
#include "physics_calculator.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

// GDExtension entry point functions
extern "C" {
    GDExtensionBool GDE_EXPORT physics_module_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
        
        init_obj.register_initializer(initialize_physics_module);
        init_obj.register_terminator(uninitialize_physics_module);
        
        return init_obj.init();
    }
}

using namespace godot;

void initialize_physics_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    ClassDB::register_class<PhysicsCalculator>();
}

void uninitialize_physics_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}
