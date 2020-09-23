module linker

import os
import term

const (
	uscope      = 'tuser'
	mscope      = 'tmachine'
	troot       = os.temp_dir() + '/symlinker'
	tsource     = troot + '/tfiles/'
	sl_test     = 'test'
	sl_test2    = 'test2'
	m_link       = 'm_link'
	invalid     = 'invalid'
	normal_file = 'normal_file'
	inexistent  = 'inexistent'
)

fn testsuite_begin() {
	u_target := get_dir(uscope)
	m_target := get_dir(mscope)
	os.rmdir_all(troot)
	os.mkdir_all(tsource)
	os.mkdir_all(u_target)
	os.mkdir_all(m_target)
	os.chdir(u_target)
	os.write_file(normal_file, '') or {
		panic(err)
	}
	os.chdir(tsource)
	os.write_file(sl_test, '') or {
		panic(err)
	}
	os.write_file(sl_test2, '') or {
		panic(err)
	}
	os.write_file(m_link, '') or {
		panic(err)
	}
	os.write_file(invalid, '') or {
		panic(err)
	}
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot)
}

fn test_create_link() {
	mut msg := create_link(sl_test, sl_test, uscope) or {
		panic(err)
	}
	assert link_exists(sl_test, uscope)
	assert msg == 'Created $uscope link `${term.bold(sl_test)}` to "$tsource$sl_test".'
	msg = create_link(sl_test, sl_test2, uscope) or {
		panic(err)
	}
	assert link_exists(sl_test2, uscope)
	assert msg == 'Created $uscope link `${term.bold(sl_test2)}` to "$tsource$sl_test".'
	msg = create_link(sl_test, sl_test, uscope) or {
		panic(err)
	}
	assert link_exists(sl_test, uscope)
	assert msg == '`${term.bold(sl_test)}` already links to "$tsource$sl_test".'
	// Create invalid link
	create_link(invalid, invalid, uscope)
	os.rm(invalid) or {
		panic(err)
	}
	assert !os.exists(invalid)
	// Create tmachine link
	msg = create_link(m_link, m_link, mscope) or {
		panic(err)
	}
	assert link_exists(m_link, mscope)
	assert msg == 'Created $mscope link `${term.bold(m_link)}` to "$tsource$m_link".'
}

// TODO: test Permission denied error
fn test_create_link_errors() {
	mut err_count := 0
	create_link(inexistent, inexistent, uscope) or {
		err_count++
		assert err == 'Source file "$inexistent" does not exist.'
	}
	create_link(sl_test2, sl_test2, uscope) or {
		err_count++
		assert err == 'Another $uscope link with name `$sl_test2` does already exist.'
	}
	create_link(sl_test, normal_file, uscope) or {
		err_count++
		assert err == 'File with name "$normal_file" does already exist.'
	}
	assert err_count == 3
}

fn test_get_real_links() {
	linkmap, msg := get_real_links(uscope)
	mut expected := map[string]string{}
	expected[invalid] = get_dir(uscope) + invalid
	expected[sl_test] = tsource + sl_test
	expected[sl_test2] = tsource + sl_test
	assert linkmap == expected
	assert msg == ''
}

// TODO: test Permission denied error
fn test_delete_link_errors() {
	mut err_count := 0
	delete_link(inexistent, uscope) or {
		err_count++
		assert err == '$uscope link `$inexistent` does not exist.'
	}
	delete_link(normal_file, uscope) or {
		err_count++
		assert err == 'Only symlinks can be deleted but "$normal_file" is no $uscope link.'
	}
	// Scope suggestion user --> machine
	delete_link(m_link, uscope) or {
		err_count++
		assert err == '`$m_link` is a $mscope link. Run `sudo symlinker del -m $m_link` to delete it.'
	}
	// Scope suggestion machine --> user
	delete_link(sl_test, mscope) or {
		err_count++
		assert err == '`$sl_test` is a $uscope link. Run `symlinker del $sl_test` to delete it.'
	}
	assert err_count == 4
}

fn test_delete_link() {
	mut msg := delete_link(sl_test, uscope) or {
		panic(err)
	}
	assert !link_exists(sl_test, uscope)
	assert msg == 'Deleted $uscope link `$sl_test` to "$tsource$sl_test".'
	msg = delete_link(sl_test2, uscope) or {
		panic(err)
	}
	assert !link_exists(sl_test2, uscope)
	assert msg == 'Deleted $uscope link `$sl_test2` to "$tsource$sl_test".'
	msg = delete_link(invalid, uscope) or {
		panic(err)
	}
	assert !link_exists(invalid, uscope)
	assert msg == 'Deleted invalid link `$invalid`.'
}

fn test_get_real_links_in_empty_scope() {
	linkmap, msg := get_real_links(uscope)
	assert linkmap.len == 0
	assert msg == 'No $uscope symlinks detected.'
}

// Helper functions
fn link_exists(name, scope string) bool {
	dir := get_dir(scope)
	return os.is_link(dir + name)
}
