Mason framework
===

This repository is about Mason 1.58 (also known as [HTML::Mason](https://metacpan.org/pod/HTML::Mason)). The official developer manual is [here](https://metacpan.org/pod/distribution/HTML-Mason/lib/HTML/Mason/Devel.pod).

Before you read this, you should get familiar with Perl syntax. I suggest [learn-perl.org](http://learn-perl.org/).

You need Linux or Mac. Windows won't work (I've tried).

1. Make sure Perl 5 is installed: `perl -v`
1. Install Apache 2 via `sudo apt install apache2` and make sure it is running by going to `http://localhost` and seeing the Apache homepage
1. Install Perl module `mod_perl` via `sudo apt install libapache2-mod-perl2`
1. Install Mason: `perl -MCPAN -e shell` and then `install HTML::Mason`

# 1. Introduction

Mason is a mechanism for embedding Perl code into plain text. It is a templating system.

Mason sits in the middle between lightweight and heavyweight solutions. It doesn't provide direct support for database connections or sessions.

# 2. Components

The basic unit of Mason code is a **component**. A component is a mix of HTML, Perl, and special Mason commands, one component per file.

A component is code that accepts inputs and generates output text. Components can call other components, like subroutines. Therefore, a component may represent a single web page, part of a web page (e.g. a navigation bar), or a shared utility function that generates no output.

A component can call another component using the `<& component_name &>` syntax, and pass parameters like this: `<& component_name, parameter => "value" &>`. An alternative to this syntax is `$m->comp()`. `$m` contains the `HTML::Mason::Request` object. The third way to call a component is via a URL.

Components can accept arguments within the `<%args>..</%args>` block. Additionally, the `$m->comp()` syntax allows getting results back rather than outputting text. Perl's `return()` function will end processing of the component. A component may return either a scalar or a list.

Components can also define subcomponents via the `<%def>` block. These are like functions only visible to the component.

Mason provides a sophisticated caching mechanism that controls how often the output of a component is rebuilt. There is also an intelligent internal caching mechanism. During execution, Mason turns each component into Perl source code on disk, then compiles the Perl code into bytecode, then executes the bytecode. To improve performance, Mason caches at each stage. The modification date of each component is checked and the cache is invalidated only when you make changes to components.

## 2.1 Component syntax

| Tag                    | Description                                                     |
| -------------          | -------------                                                   |
| `<% ... %>`            | Substitution. Perl code that is evaluated and sent as output. It is possible to escape the contents before it is sent as output. For example: `<% $homepage` &#124; `u %>` for URI escaping. &#124; h can be used for HTML entity escaping.    |
| `% ...`                | A single line of Perl code. The `%` **must** be at the beginning of the line.    |
| `<%perl> ... </%perl>` | A block of Perl code                                            |
| `<& ... &>`            | A call to another component                                     |
| `<%init> ... </%init>` | Perl code that executes before any other component code, except for code in `<%once>` or `<%shared>` blocks. It runs every time the component is called. It is typically used to check arguments, create objects or retrieve data from a database. Note that the variables defined here aren't visible to subcomponents. |
| `<%shared> .. </%shared>`   | Perl code that runs once per request. Unlike the `<%init>` block, the variables declared here are in scope both in the component and in any subcomponent or methods it may contain. |
| `<%args> ... </%args>` | A component's input argument declarations. Default values for arguments can be specified. The exact values (without the defaults) that were passed to the component can be accessed through the `%ARGS` variable. When an argument is an array or a hash, the caller component **must** use references.                  |
| `<%filter> .. </%filter>`   | Perl Code that runs after the component has finished running. It is given the entire output of the component in the special variable `$_` |
| `<%once> ... </%once>`      | Executed when the component is loaded into memory. It is used to create things like database handles. Any variables declared here remain in scope until the components is flushed from memory or the Perl interpreter shuts down.  |
| `<%cleanup> .. </%cleanup>` | The counterpart to the `<%init>` block. It is used to free up resources, but it is technically equivalent to placing a `%perl` block at the end of the component. They are **not** executed if the component aborts. |
| `<%text> ... </%text>`      | This block is printed exactly as it is, without any variable substitution or execution.   |
| `<%doc> .. </%doc>`          | This block is intended only for documentation purposes. |
| `<%flags> .. </%flags>`     | This block is used to declare 1 or more key-value pairs of official Mason flags, to affect component behavior. For example, the flag `inherit` is used to specify the parent component. Flags **only** refer to the current component. |
| `<%attr> ... </%attr>`      | This block is similar to `<%flags>` but its key-value pairs can be part of the inheritance chain. So the parent component can use them like `$m->base_comp->attr('name')`  |
| `<%def .name> ... </%def>`        | Used to create subcomponents (i.e. components that can only be accessed within a component). They require a name in the tag. |
| `<%method> .. </%method>`    | Similar to a `<%def>` block, but the methods defined here are visible outside of the component and can be inherited. |
| `<&`&#124;` .filter> ... </&>`    | Calls a component and applies the named filter. The output of the called component can be retrieved via `$m->content` |


# 3. Object-Style Component Inheritance

Components can inherit behavior from other components, like classes. Typically, each component inherits from a single component called the `autohandler`. Mason calls the parent component automatically. The child component specifies attributes for the parent component via the `<%attr>..</%attr>` block. An attribute is a component property that inherits via Mason's inheritance chain.

# 4. Integration with Apache and mod_perl

One of Apache's most powerful features is `mod_perl`, which lets you use Perl within the server process. Mason is designed to fully cooperate with `mod_perl`: Apache can serve Mason components directly. When running under `mod_perl`, all components have access to the global variable `$r`.

A basic understanding of how Mason processes requests is useful. Each request is defined by an initial component path and a set of arguments passed to that component. Requests are handled by the Interpreter object. Interpreter asks the Resolver to fetch the requested component from disk. Then the Interpreter asks the Compiler to create a compiled representation of the component. Afterwards, Mason creates a request object and tells it to execute that component. Any output a component generates is sent to STDOUT. If an error occurs during any part of this process, Mason throws an exception via Perl's `die()` function.

The component root is the folder or list of folders under which Mason expects to find all the components. If the component root is `/var/www/mason`, and you want to execute the component `/view/books.comp`, Mason will look for a file called `/var/www/mason/view/books.comp`. When running under Apache, Mason will default to using the web server's document root as component root.

# 5. Special components: dhandlers and autohandlers

**Dhandlers** (_default handler_) provide a flexible way to create "virtual" URLs that don't correspond directly to components on disk. If the web server receives a request for `/archives/2001/march/21` and no such Mason component exists, it will sequentially look for `/archives/2001/march/dhandler`, `/archives/2001/dhandler`, `/archives/dhandler` and `/dhandler`. If the first dhandler found is `/archives/dhandler`, `$m->dhandler_arg` wil return `2001/march/21`. Any component may decline to handle a request so that Mason continues its search for dhandlers up the component tree. This is done via `$m->decline`.

**Autohandlers** let you control many structural aspects of a website in an object-oriented way. A component may specify a parent component using the `inherit` flag, and if they don't, the autohandler in the same directory becomes the parent.

Details of component processing:

1. A request comes to the URL `/welcome.html`. Mason translates it to a request for the `/welcome.html` component.
1. The component is found, so the `dhandler` mechanism is not invoked.
1. Since `welcome.html` doesn't specify a parent component, Mason looks for an `autohandler` in the same directory.
1. Because there are no directories above `/autohandler` and `/autohandler` doesn't specify a parent, the construction of the inheritance hierarchy is complete.
1. Mason processes the `/autohandler`. When it sees the call to `$m->call_next`, it starts processing `welcome.html`.
1. Control passes back to `/autohandler`.

Terminology:

- Requested component: the component originally requested by a URL. This is determined only once per request. Accessible via `$m->request_comp`.
- Current component: component currently executing at any component. Accessible via `$m->current_comp`.
- Base component: bottommost child of the current component. Accessible via `$m->base_comp`.

# 6. API

- Request: the class method `HTML::Mason::Request->instance()` returns the current Mason request object. This is useful if yu have code outside of a Mason component that needs to access the request object. Inside components, you can use `$m`.
- Component
- Buffer
