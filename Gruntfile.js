module.exports = function(grunt) {

    grunt.initConfig({
        watch: {
            copy: {
                files: ['src/main/resources/ui/**/*.js','src/main/resources/script/*.js','src/main/resources/**/*.groovy', 'src/main/resources/ui/**/*.html', 'src/main/resources/conf/*.json', 'src/main/resources/ui/**/*.less', 'src/main/resources/ui/**/*.css'],
                tasks: [ 'sync' ]
            }
        },
        sync: {
            custom: {
                files: [{
                    cwd     : 'src/main/resources',
                    src     : ['**/*'], 
                    dest    : 'target/sqlfiddle',
                    flatten : false,
                    expand  : true
                }]
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-sync');
    
    grunt.registerTask('default', ['watch']);

};
